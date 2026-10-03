import XCTest
@testable import Podcasts_Bin

@MainActor
final class HistoryViewModelTests: XCTestCase {
    private var isolated: IsolatedManagers!

    override func setUp() async throws {
        isolated = IsolatedManagers()
    }

    override func tearDown() async throws {
        isolated.tearDown()
    }

    func test_fetchHistory_listsNewestFirstAndLimitsTheShelf() async {
        let manager = MockEpisodesManager()
        manager.history = (1...12).map { makeEpisode("\($0)") }
        let sut = HistoryViewModel(episodesManager: manager, downloadManager: isolated.downloadManager())

        await sut.fetchHistory()

        XCTAssertEqual(sut.episodes.first?.title, "Episode 1")
        XCTAssertEqual(sut.episodes.count, 12)
        XCTAssertEqual(sut.recentEpisodes.count, 10)
    }

    func test_playingAnEpisode_reloadsHistory() async throws {
        let manager = MockEpisodesManager()
        let sut = HistoryViewModel(episodesManager: manager, downloadManager: isolated.downloadManager())
        await sut.fetchHistory()

        try await manager.saveInHistory(episode: makeEpisode("played"))

        let reloaded = await waitUntil { sut.episodes.map(\.title) == ["Episode played"] }
        XCTAssertTrue(reloaded)
    }

    func test_failedFetch_exposesError() async {
        let manager = MockEpisodesManager()
        manager.shouldFail = true
        let sut = HistoryViewModel(episodesManager: manager, downloadManager: isolated.downloadManager())

        await sut.fetchHistory()

        XCTAssertNotNil(sut.errorMessage)
    }

    func test_fetchHistory_identifiesEarlierDownloads() async throws {
        let episode = makeEpisode("downloaded")
        try isolated.storeUnidentifiedDownload(for: episode.streamUrl)
        let downloads = isolated.downloadManager()
        let manager = MockEpisodesManager()
        manager.history = [episode]

        await HistoryViewModel(episodesManager: manager, downloadManager: downloads).fetchHistory()

        XCTAssertEqual(downloads.unidentifiedCount, 0)
        XCTAssertEqual(downloads.library.map(\.episode.title), ["Episode downloaded"])
    }
}
