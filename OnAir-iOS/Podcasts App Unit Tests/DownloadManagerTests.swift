import AVFoundation
import XCTest
@testable import Podcasts_Bin

@MainActor
final class DownloadManagerTests: XCTestCase {
    /// AVPlayer finishes configuring asynchronously and can crash if released immediately.
    private static var retainedPlayers: [AVPlayer] = []
    private var directory: URL!
    private var store: DownloadStore!
    private var manager: DownloadManager!
    private var defaults: UserDefaults!
    private var defaultsSuite: String!

    private let streamUrl = "https://example.com/shows/episode-1.mp3?token=abc"

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("DownloadManagerTests-\(UUID().uuidString)")
        store = DownloadStore(directory: directory)
        defaultsSuite = "DownloadManagerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuite)
        manager = makeManager()
    }

    override func tearDown() async throws {
        DownloadURLProtocol.respond = nil
        DownloadURLProtocol.lastRequest = nil
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: defaultsSuite)
    }

    /// An ephemeral session stubbed with a URLProtocol; tests never touch the network.
    private func makeManager(defaults: UserDefaults? = nil) -> DownloadManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DownloadURLProtocol.self]
        return DownloadManager(store: store, configuration: configuration,
                               defaults: defaults ?? self.defaults, monitorsNetwork: false)
    }

    private func episode(_ streamUrl: String? = nil, title: String = "Episode") throws -> Episode {
        let data = try JSONSerialization.data(withJSONObject: [
            "title": title, "subtitle": "", "pubDate": 0, "description": "", "author": "Author",
            "streamUrl": streamUrl ?? self.streamUrl, "podcastFeedUrl": "https://example.com/feed"
        ])
        return try JSONDecoder().decode(Episode.self, from: data)
    }

    private func waitForState(_ expected: DownloadState, timeout: TimeInterval = 5) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while manager.state(for: streamUrl) != expected && Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(manager.state(for: streamUrl), expected)
    }

    private func temporaryFile(_ contents: String) throws -> URL {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data(contents.utf8).write(to: file)
        return file
    }

    // MARK: - DownloadStore

    func test_fileExtension_prefersURLThenMimeTypeThenMP3() {
        XCTAssertEqual(DownloadStore.fileExtension(for: "https://e.com/a.M4A?x=1", mimeType: "audio/mpeg"), "m4a")
        XCTAssertEqual(DownloadStore.fileExtension(for: "https://e.com/play?id=7", mimeType: "audio/mp4"), "m4a")
        XCTAssertEqual(DownloadStore.fileExtension(for: "https://e.com/play?id=7", mimeType: nil), "mp3")
    }

    func test_fileStem_isStablePerEpisode() {
        XCTAssertEqual(DownloadStore.fileStem(for: streamUrl), DownloadStore.fileStem(for: streamUrl))
        XCTAssertNotEqual(DownloadStore.fileStem(for: streamUrl), DownloadStore.fileStem(for: streamUrl + "2"))
    }

    func test_store_movesFileIntoPlaceAndReplacesEarlierCopy() throws {
        try store.store(try temporaryFile("first"), for: streamUrl, mimeType: nil)
        let file = try store.store(try temporaryFile("second"), for: streamUrl, mimeType: "audio/mp4")

        XCTAssertEqual(store.existingFile(for: streamUrl), file)
        XCTAssertEqual(file.pathExtension, "mp3")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "second")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
    }

    func test_store_excludesDownloadsFromBackup() throws {
        try store.store(try temporaryFile("audio"), for: streamUrl, mimeType: nil)
        let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }

    // MARK: - DownloadManager

    func test_download_savesFileAndReportsDownloaded() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio bytes".utf8)) }

        manager.download(try episode())
        XCTAssertEqual(manager.state(for: streamUrl), .downloading(progress: 0))
        try await waitForState(.downloaded)

        let file = try XCTUnwrap(manager.localFile(for: streamUrl))
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "audio bytes")
    }

    func test_download_httpErrorReportsFailure() async throws {
        DownloadURLProtocol.respond = { _ in (404, Data()) }

        manager.download(try episode())
        try await waitForState(.failed(message: DownloadError.httpStatus(404).localizedDescription))
        XCTAssertNil(manager.localFile(for: streamUrl))
    }

    func test_download_rejectsNonHTTPURLs() throws {
        manager.download(try episode("file:///private/tmp/episode.mp3"))
        guard case .failed = manager.state(for: "file:///private/tmp/episode.mp3") else {
            return XCTFail("Expected a failure state")
        }
    }

    func test_remove_deletesTheFile() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode())
        try await waitForState(.downloaded)

        manager.remove(streamUrl)

        XCTAssertEqual(manager.state(for: streamUrl), .notDownloaded)
        XCTAssertNil(store.existingFile(for: streamUrl))
    }

    func test_cancel_resetsState() throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode())
        manager.cancel(streamUrl)
        XCTAssertEqual(manager.state(for: streamUrl), .notDownloaded)
    }

    func test_newManager_findsEpisodesDownloadedEarlier() throws {
        try store.store(try temporaryFile("audio"), for: streamUrl, mimeType: nil)
        manager = makeManager()
        XCTAssertEqual(manager.state(for: streamUrl), .downloaded)
        XCTAssertNotNil(manager.localFile(for: streamUrl))
    }

    func test_progress_isClampedAndIgnoredWhenNotDownloading() throws {
        manager.handleProgress(streamUrl, progress: 0.5)
        XCTAssertEqual(manager.state(for: streamUrl), .notDownloaded)

        DownloadURLProtocol.respond = { _ in (200, Data()) }
        manager.download(try episode())
        manager.handleProgress(streamUrl, progress: 1.7)
        XCTAssertEqual(manager.state(for: streamUrl), .downloading(progress: 1))
        manager.cancel(streamUrl)
    }

    func test_download_isListedInLibraryWithDetailsAndSize() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data(repeating: 1, count: 2048)) }
        manager.download(try episode(title: "Offline episode"))
        try await waitForState(.downloaded)

        XCTAssertEqual(manager.library.map(\.episode.title), ["Offline episode"])
        XCTAssertEqual(manager.library.first?.episode.podcastFeedUrl, "https://example.com/feed")
        XCTAssertEqual(manager.library.first?.fileSize, 2048)
        XCTAssertEqual(manager.totalBytes, 2048)
    }

    func test_activeDownloads_includeEpisodeDetails() throws {
        DownloadURLProtocol.respond = { _ in (200, Data()) }
        manager.download(try episode(title: "In progress"))
        XCTAssertEqual(manager.activeDownloads.map(\.episode.title), ["In progress"])
        manager.cancel(streamUrl)
        XCTAssertTrue(manager.activeDownloads.isEmpty)
        XCTAssertNil(store.metadata(for: streamUrl), "Cancelling should drop the saved details")
    }

    func test_libraryIsRebuiltFromDiskAfterRelaunch() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode(title: "Kept"))
        try await waitForState(.downloaded)

        manager = makeManager()

        XCTAssertEqual(manager.library.map(\.episode.title), ["Kept"])
    }

    func test_removeAllDownloads_deletesFilesAndDetails() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode())
        try await waitForState(.downloaded)

        manager.removeAllDownloads()

        XCTAssertTrue(manager.library.isEmpty)
        XCTAssertEqual(manager.totalBytes, 0)
        XCTAssertEqual(manager.state(for: streamUrl), .notDownloaded)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func test_wifiOnly_persistsAndBlocksCellularForNewDownloads() async throws {
        XCTAssertFalse(manager.wifiOnly)
        manager.setWiFiOnly(true)
        XCTAssertTrue(makeManager().wifiOnly, "The setting should survive a relaunch")

        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode())
        try await waitForState(.downloaded)

        XCTAssertEqual(DownloadURLProtocol.lastRequest?.allowsCellularAccess, false)
    }

    func test_cellularAllowedByDefault() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode())
        try await waitForState(.downloaded)
        XCTAssertEqual(DownloadURLProtocol.lastRequest?.allowsCellularAccess, true)
    }

    func test_downloadsWithoutDetails_areIdentifiedFromKnownEpisodes() throws {
        // A download saved before episode details were recorded: audio only, no sidecar.
        try store.store(try temporaryFile("audio"), for: streamUrl, mimeType: nil)
        manager = makeManager()
        XCTAssertTrue(manager.library.isEmpty)
        XCTAssertEqual(manager.unidentifiedCount, 1)
        XCTAssertEqual(manager.unidentifiedBytes, 5)

        manager.identifyDownloads(from: [try episode("https://example.com/other.mp3"), try episode(title: "Recovered")])

        XCTAssertEqual(manager.library.map(\.episode.title), ["Recovered"])
        XCTAssertEqual(manager.unidentifiedCount, 0)
        XCTAssertEqual(manager.unidentifiedBytes, 0)
    }

    func test_removeUnidentifiedDownloads_keepsIdentifiedOnes() async throws {
        DownloadURLProtocol.respond = { _ in (200, Data("audio".utf8)) }
        manager.download(try episode(title: "Known"))
        try await waitForState(.downloaded)
        try store.store(try temporaryFile("old"), for: "https://example.com/old.mp3", mimeType: nil)
        manager = makeManager()
        XCTAssertEqual(manager.unidentifiedCount, 1)

        manager.removeUnidentifiedDownloads()

        XCTAssertEqual(manager.unidentifiedCount, 0)
        XCTAssertEqual(manager.library.map(\.episode.title), ["Known"])
        XCTAssertEqual(manager.state(for: "https://example.com/old.mp3"), .notDownloaded)
    }

    // MARK: - Playback

    func test_playback_prefersTheDownloadedFile() throws {
        let local = try store.store(try temporaryFile("audio"), for: streamUrl, mimeType: nil)
        let data = try JSONSerialization.data(withJSONObject: [
            "title": "Episode", "subtitle": "", "pubDate": 0, "description": "", "author": "Author", "streamUrl": streamUrl
        ])
        let episode = try JSONDecoder().decode(Episode.self, from: data)
        let player = AVPlayer()
        Self.retainedPlayers.append(player)
        let suite = "DownloadManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let sut = PlaybackManager(player: player, defaults: defaults, systemPlaybackEnabled: false,
                                  localFile: { [store] in store!.existingFile(for: $0) }, saveHistory: { _ in })
        defer { sut.close() }

        sut.load(episode, queue: [episode], autoplay: false)

        XCTAssertEqual((player.currentItem?.asset as? AVURLAsset)?.url, local)
    }
}

private final class DownloadURLProtocol: URLProtocol {
    static var respond: ((URLRequest) -> (Int, Data))?
    static var lastRequest: URLRequest?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let respond = Self.respond else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        Self.lastRequest = request
        let (status, data) = respond(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Length": "\(data.count)"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
