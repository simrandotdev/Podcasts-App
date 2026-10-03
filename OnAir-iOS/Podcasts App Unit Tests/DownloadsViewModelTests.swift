import XCTest
@testable import Podcasts_Bin

@MainActor
final class DownloadsViewModelTests: XCTestCase {
    private var isolated: IsolatedManagers!

    override func setUp() async throws {
        isolated = IsolatedManagers()
    }

    override func tearDown() async throws {
        isolated.tearDown()
    }

    func test_library_listsDownloadsAsEpisodes() throws {
        let episode = makeEpisode("offline")
        try isolated.storeUnidentifiedDownload(for: episode.streamUrl)
        try isolated.downloadStore.saveMetadata(episode)
        let sut = DownloadsViewModel(manager: isolated.downloadManager())

        XCTAssertEqual(sut.library.map(\.episode.title), ["Episode offline"])
        XCTAssertEqual(sut.state(for: EpisodeViewModel(episode: episode)), .downloaded)
        XCTAssertGreaterThan(sut.totalBytes, 0)
    }

    func test_remove_deletesTheDownload() throws {
        let episode = makeEpisode("offline")
        try isolated.storeUnidentifiedDownload(for: episode.streamUrl)
        try isolated.downloadStore.saveMetadata(episode)
        let sut = DownloadsViewModel(manager: isolated.downloadManager())

        sut.remove(EpisodeViewModel(episode: episode))

        XCTAssertTrue(sut.library.isEmpty)
        XCTAssertEqual(sut.state(for: EpisodeViewModel(episode: episode)), .notDownloaded)
    }

    func test_download_reportsEpisodesThatCantBeDownloaded() {
        let sut = DownloadsViewModel(manager: isolated.downloadManager())
        let local = EpisodeViewModel(episode: Episode(title: "Local", subtitle: "", pubDate: Date(), description: "",
                                                      author: "", streamUrl: "file:///private/tmp/local.mp3"))

        sut.download(local)

        guard case .failed = sut.state(for: local) else { return XCTFail("Expected a failed download") }
    }

    func test_wifiOnly_isSavedByTheManager() {
        let manager = isolated.downloadManager()
        let sut = DownloadsViewModel(manager: manager)

        sut.wifiOnly = true

        XCTAssertTrue(manager.wifiOnly)
        XCTAssertTrue(isolated.defaults.bool(forKey: DownloadManager.wifiOnlyKey))
    }
}
