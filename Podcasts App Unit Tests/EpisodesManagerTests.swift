import Combine
import XCTest
@testable import Podcasts_Bin

final class EpisodesManagerTests: XCTestCase {
    private var repository: MockEpisodesRepository!
    private var sut: EpisodesManager!
    private var changes = 0
    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        repository = MockEpisodesRepository()
        sut = EpisodesManager(repository: repository)
        changes = 0
        subscription = sut.historyDidChange.sink { [unowned self] in self.changes += 1 }
    }

    func test_fetchEpisodes_readsThePodcastsFeed() async throws {
        let episodes = try await sut.fetchEpisodes(forFeedUrl: "https://example.com/feed")
        XCTAssertEqual(repository.feeds, ["https://example.com/feed"])
        XCTAssertEqual(episodes.first?.podcastFeedUrl, "https://example.com/feed")
    }

    func test_saveInHistory_savesAndAnnouncesTheChange() async throws {
        try await sut.saveInHistory(episode: makeEpisode("1"))
        try await sut.saveInHistory(episode: makeEpisode("2"))

        let history = try await sut.fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Episode 2", "Episode 1"])
        XCTAssertEqual(changes, 2)
    }

    func test_failedSave_throwsWithoutAnnouncingAChange() async {
        repository.shouldFail = true
        do {
            try await sut.saveInHistory(episode: makeEpisode("1"))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(changes, 0)
        }
    }
}
