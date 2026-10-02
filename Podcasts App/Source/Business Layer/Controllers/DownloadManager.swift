import Foundation
import Network

enum DownloadState: Equatable {
    case notDownloaded
    /// Fraction received, 0...1 (0 until the size is known).
    case downloading(progress: Double)
    case downloaded
    case failed(message: String)
}

/// Downloads episodes for offline listening with a background URLSession, so downloads continue
/// while the app is suspended or not running. Episodes are identified by `streamUrl`.
@MainActor
final class DownloadManager: ObservableObject {
    static let sessionIdentifier = "ca.bytesizedsoftware.hello-podcasts.downloads"

    /// One instance per process: iOS allows only one session per background identifier, and the
    /// app delegate must be able to reconnect to it when the system relaunches the app for events.
    static let shared = DownloadManager()

    /// Set by the app delegate when iOS relaunches the app to deliver background download events.
    static var backgroundEventsCompletionHandler: (() -> Void)?

    static let wifiOnlyKey = "downloadsWiFiOnly"

    /// Downloads in progress or failed. Finished downloads are tracked by `downloadedStems`.
    @Published private(set) var activeStates: [String: DownloadState] = [:]
    @Published private(set) var downloadedStems: Set<String>
    /// Finished downloads with their details, newest first.
    @Published private(set) var library: [DownloadStore.Item] = []
    /// Bytes used by all downloads.
    @Published private(set) var totalBytes: Int64 = 0
    /// Downloads whose episode isn't known yet (saved before details were recorded).
    @Published private(set) var unidentifiedCount = 0
    @Published private(set) var unidentifiedBytes: Int64 = 0
    /// Only download over Wi-Fi or wired networks. Applies to downloads started after it changes.
    @Published private(set) var wifiOnly: Bool
    /// Whether the device currently has a Wi-Fi or wired connection.
    @Published private(set) var hasWiFi = true

    let store: DownloadStore
    private let defaults: UserDefaults
    private var session: URLSession!
    private var tasks: [String: URLSessionDownloadTask] = [:]
    /// Details of episodes being downloaded, for the Downloads screen.
    private var pendingEpisodes: [String: EpisodeViewModel] = [:]
    private var pathMonitor: NWPathMonitor?

    init(store: DownloadStore = .standard, configuration: URLSessionConfiguration? = nil,
         defaults: UserDefaults = .standard, monitorsNetwork: Bool = true) {
        self.store = store
        self.defaults = defaults
        downloadedStems = store.downloadedStems()
        wifiOnly = defaults.bool(forKey: Self.wifiOnlyKey)

        // Callbacks are wired before the session exists so no relaunch events are missed.
        let delegate = DownloadSessionDelegate(store: store)
        delegate.onProgress = { [weak self] streamUrl, progress in
            Task { @MainActor in self?.handleProgress(streamUrl, progress: progress) }
        }
        delegate.onFinished = { [weak self] streamUrl, result in
            Task { @MainActor in self?.handleFinished(streamUrl, result: result) }
        }
        delegate.onCancelled = { [weak self] streamUrl in
            Task { @MainActor in self?.handleCancelled(streamUrl) }
        }
        delegate.onBackgroundEventsFinished = {
            Task { @MainActor in
                Self.backgroundEventsCompletionHandler?()
                Self.backgroundEventsCompletionHandler = nil
            }
        }
        session = URLSession(configuration: configuration ?? Self.backgroundConfiguration(),
                             delegate: delegate, delegateQueue: nil)
        refreshLibrary()
        restoreRunningTasks()
        if monitorsNetwork { startMonitoringNetwork() }
    }

    deinit {
        pathMonitor?.cancel()
    }

    private func startMonitoringNetwork() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let hasWiFi = path.status == .satisfied
                && (path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet))
            Task { @MainActor in self?.hasWiFi = hasWiFi }
        }
        monitor.start(queue: DispatchQueue(label: "DownloadManager.network"))
        pathMonitor = monitor
    }

    private func refreshLibrary() {
        library = store.items()
        totalBytes = store.totalSize()
        let unidentified = store.filesWithoutMetadata()
        unidentifiedCount = unidentified.count
        unidentifiedBytes = unidentified.reduce(0) { $0 + $1.size }
    }

    /// Recovers details for downloads saved before they were recorded. Files are named by a hash of
    /// the stream URL, so any episode the app sees again (in history or a podcast's episode list)
    /// can be matched to its file.
    func identifyDownloads(from episodes: [EpisodeViewModel]) {
        guard unidentifiedCount > 0 else { return }
        var recovered = false
        for episode in episodes where downloadedStems.contains(DownloadStore.fileStem(for: episode.streamUrl))
            && store.metadata(for: episode.streamUrl) == nil {
            try? store.saveMetadata(Episode(episodeViewModel: episode))
            recovered = true
        }
        if recovered { refreshLibrary() }
    }

    /// Deletes downloads whose episode couldn't be identified.
    func removeUnidentifiedDownloads() {
        store.removeFilesWithoutMetadata()
        downloadedStems = store.downloadedStems()
        refreshLibrary()
    }

    private static func backgroundConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.sessionSendsLaunchEvents = true
        // The user asked for this episode now; don't let the system defer it.
        configuration.isDiscretionary = false
        return configuration
    }

    // MARK: - Queries

    func state(for streamUrl: String) -> DownloadState {
        if let state = activeStates[streamUrl] { return state }
        return downloadedStems.contains(DownloadStore.fileStem(for: streamUrl)) ? .downloaded : .notDownloaded
    }

    /// True when downloads are paused until Wi-Fi is available.
    var isWaitingForWiFi: Bool { wifiOnly && !hasWiFi }

    /// Downloads in progress or failed, with their episode details, for the Downloads screen.
    var activeDownloads: [(episode: EpisodeViewModel, state: DownloadState)] {
        activeStates.compactMap { streamUrl, state in
            guard let episode = pendingEpisodes[streamUrl] ?? store.metadata(for: streamUrl).map(EpisodeViewModel.init)
            else { return nil }
            return (episode, state)
        }
        .sorted { $0.episode.title < $1.episode.title }
    }

    /// The downloaded file to play instead of streaming, if there is one.
    func localFile(for streamUrl: String) -> URL? {
        guard downloadedStems.contains(DownloadStore.fileStem(for: streamUrl)) else { return nil }
        return store.existingFile(for: streamUrl)
    }

    // MARK: - Actions

    func setWiFiOnly(_ isOn: Bool) {
        wifiOnly = isOn
        defaults.set(isOn, forKey: Self.wifiOnlyKey)
    }

    func download(_ episode: EpisodeViewModel) {
        let streamUrl = episode.streamUrl
        switch state(for: streamUrl) {
        case .downloading, .downloaded: return
        case .notDownloaded, .failed: break
        }
        guard let url = URL(string: streamUrl), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            activeStates[streamUrl] = .failed(message: "This episode doesn't have a downloadable audio URL.")
            return
        }
        pendingEpisodes[streamUrl] = episode
        // Saved now so a download that finishes while the app isn't running can still be listed.
        try? store.saveMetadata(Episode(episodeViewModel: episode))
        var request = URLRequest(url: url)
        // Background sessions hold the task until an allowed network is available.
        request.allowsCellularAccess = !wifiOnly
        let task = session.downloadTask(with: request)
        // Survives relaunches, so finished background downloads can be matched to their episode.
        task.taskDescription = streamUrl
        tasks[streamUrl] = task
        activeStates[streamUrl] = .downloading(progress: 0)
        task.resume()
    }

    func cancel(_ streamUrl: String) {
        tasks.removeValue(forKey: streamUrl)?.cancel()
        activeStates[streamUrl] = nil
        pendingEpisodes[streamUrl] = nil
        // Nothing was downloaded, so drop the details saved when it started.
        if !downloadedStems.contains(DownloadStore.fileStem(for: streamUrl)) { store.remove(streamUrl) }
    }

    func remove(_ streamUrl: String) {
        cancel(streamUrl)
        store.remove(streamUrl)
        downloadedStems.remove(DownloadStore.fileStem(for: streamUrl))
        refreshLibrary()
    }

    /// Deletes every finished download. Downloads in progress keep going.
    func removeAllDownloads() {
        let inProgress = Set(activeStates.keys)
        store.removeAll(keeping: inProgress)
        downloadedStems = store.downloadedStems()
        refreshLibrary()
    }

    // MARK: - Session events (internal for tests)

    func handleProgress(_ streamUrl: String, progress: Double) {
        // Ignore late progress for a download that was cancelled or already finished.
        guard case .downloading = activeStates[streamUrl] else { return }
        activeStates[streamUrl] = .downloading(progress: min(max(progress, 0), 1))
    }

    func handleFinished(_ streamUrl: String, result: Result<URL, Error>) {
        tasks[streamUrl] = nil
        switch result {
        case .success:
            downloadedStems.insert(DownloadStore.fileStem(for: streamUrl))
            activeStates[streamUrl] = nil
            pendingEpisodes[streamUrl] = nil
            refreshLibrary()
        case .failure(let error):
            activeStates[streamUrl] = .failed(message: error.localizedDescription)
        }
    }

    func handleCancelled(_ streamUrl: String) {
        tasks[streamUrl] = nil
        activeStates[streamUrl] = nil
        pendingEpisodes[streamUrl] = nil
    }

    /// After a relaunch, pick up downloads that kept running while the app was gone.
    private func restoreRunningTasks() {
        session.getAllTasks { [weak self] tasks in
            let running = tasks.compactMap { task -> (String, URLSessionDownloadTask)? in
                guard let task = task as? URLSessionDownloadTask, let streamUrl = task.taskDescription,
                      task.state == .running || task.state == .suspended else { return nil }
                return (streamUrl, task)
            }
            Task { @MainActor in
                guard let self else { return }
                for (streamUrl, task) in running where self.tasks[streamUrl] == nil {
                    self.tasks[streamUrl] = task
                    self.activeStates[streamUrl] = .downloading(progress: task.progress.fractionCompleted)
                }
            }
        }
    }
}

enum DownloadError: LocalizedError {
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code): return "The download failed (HTTP \(code))."
        }
    }
}

/// Receives URLSession callbacks on the session's queue and forwards them to `DownloadManager`.
final class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {
    let store: DownloadStore
    var onProgress: (String, Double) -> Void = { _, _ in }
    var onFinished: (String, Result<URL, Error>) -> Void = { _, _ in }
    var onCancelled: (String) -> Void = { _ in }
    var onBackgroundEventsFinished: () -> Void = {}

    init(store: DownloadStore) {
        self.store = store
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let streamUrl = downloadTask.taskDescription, totalBytesExpectedToWrite > 0 else { return }
        onProgress(streamUrl, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let streamUrl = downloadTask.taskDescription else { return }
        if let response = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            onFinished(streamUrl, .failure(DownloadError.httpStatus(response.statusCode)))
            return
        }
        // The temporary file is deleted when this method returns, so move it now.
        do {
            let file = try store.store(location, for: streamUrl, mimeType: downloadTask.response?.mimeType)
            onFinished(streamUrl, .success(file))
        } catch {
            onFinished(streamUrl, .failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Success was already handled in didFinishDownloadingTo.
        guard let error, let streamUrl = task.taskDescription else { return }
        if (error as NSError).code == NSURLErrorCancelled {
            onCancelled(streamUrl)
        } else {
            onFinished(streamUrl, .failure(error))
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        onBackgroundEventsFinished()
    }
}
