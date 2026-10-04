import XCTest
@testable import Podcasts_Bin

final class EpisodesManagerTests: XCTestCase {
    private var repository: MockEpisodesRepository!
    private var sut: EpisodesManager!

    override func setUp() {
        super.setUp()
        repository = MockEpisodesRepository()
        sut = EpisodesManager(repository: repository)
    }

    func test_fetchEpisodes_readsThePodcastsFeed() async throws {
        let episodes = try await sut.fetchEpisodes(forFeedUrl: "https://example.com/feed")
        XCTAssertEqual(repository.feeds, ["https://example.com/feed"])
        XCTAssertEqual(episodes.first?.podcastFeedUrl, "https://example.com/feed")
    }

    @MainActor
    func test_saveInHistory_savesAndAnnouncesTheChange() async throws {
        let changes = ChangeCounter(sut.historyChanges())

        try await sut.saveInHistory(episode: makeEpisode("1"))
        let announcedFirst = await waitUntil { changes.count == 1 }
        try await sut.saveInHistory(episode: makeEpisode("2"))
        let announcedSecond = await waitUntil { changes.count == 2 }

        let history = try await sut.fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Episode 2", "Episode 1"])
        XCTAssertTrue(announcedFirst)
        XCTAssertTrue(announcedSecond)
    }

    @MainActor
    func test_failedSave_throwsWithoutAnnouncingAChange() async {
        let changes = ChangeCounter(sut.historyChanges())
        repository.shouldFail = true
        do {
            try await sut.saveInHistory(episode: makeEpisode("1"))
            XCTFail("Expected an error")
        } catch {
            let announced = await waitUntil(timeout: 0.2) { changes.count > 0 }
            XCTAssertFalse(announced)
        }
    }
}
