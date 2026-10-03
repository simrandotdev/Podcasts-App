import Foundation
import Combine

/// Download state and controls for every view that shows downloads: the Downloads tab, download
/// buttons, episode details and Settings. Wraps the app's `DownloadManager`.
@MainActor
final class DownloadsViewModel: ObservableObject {
    /// A finished download.
    struct Item: Identifiable {
        let episode: EpisodeViewModel
        let fileSize: Int64
        var id: String { episode.streamUrl }
    }

    /// Finished downloads, newest first.
    @Published private(set) var library: [Item] = []

    private let manager: DownloadManager
    private var subscription: AnyCancellable?

    /// - Parameter manager: Defaults to the app's shared download manager.
    init(manager: DownloadManager? = nil) {
        let manager = manager ?? .shared
        self.manager = manager
        manager.$library
            .map { $0.map { Item(episode: EpisodeViewModel(episode: $0.episode), fileSize: $0.fileSize) } }
            .assign(to: &$library)
        // Republish progress and state changes so download buttons update while downloading.
        subscription = manager.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - State

    /// Downloads in progress or failed.
    var activeDownloads: [(episode: EpisodeViewModel, state: DownloadState)] {
        manager.activeDownloads.map { (EpisodeViewModel(episode: $0.episode), $0.state) }
    }

    /// Bytes used by all downloads.
    var totalBytes: Int64 { manager.totalBytes }
    /// True when downloads are paused until Wi-Fi is available.
    var isWaitingForWiFi: Bool { manager.isWaitingForWiFi }
    /// Downloads whose episode isn't known yet (saved before details were recorded).
    var unidentifiedCount: Int { manager.unidentifiedCount }
    var unidentifiedBytes: Int64 { manager.unidentifiedBytes }

    /// Only download over Wi-Fi or wired networks. Applies to downloads started after it changes.
    var wifiOnly: Bool {
        get { manager.wifiOnly }
        set { manager.setWiFiOnly(newValue) }
    }

    func state(for episode: EpisodeViewModel) -> DownloadState {
        manager.state(for: episode.streamUrl)
    }

    // MARK: - Actions

    func download(_ episode: EpisodeViewModel) { manager.download(Episode(episodeViewModel: episode)) }
    func cancel(_ episode: EpisodeViewModel) { manager.cancel(episode.streamUrl) }
    func remove(_ episode: EpisodeViewModel) { manager.remove(episode.streamUrl) }
    /// Deletes every finished download. Downloads in progress keep going.
    func removeAll() { manager.removeAllDownloads() }
    /// Deletes downloads whose episode couldn't be identified.
    func removeUnidentified() { manager.removeUnidentifiedDownloads() }
}
