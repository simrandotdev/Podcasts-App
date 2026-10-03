import XCTest
@testable import Podcasts_Bin

@MainActor
final class NewEpisodesViewModelTests: XCTestCase {
    private var isolated: IsolatedManagers!
    private let feed = "https://example.com/feed"
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var feedEpisodes: [Episode] = []

    override func setUp() async throws {
        isolated = IsolatedManagers()
    }

    override func tearDown() async throws {
        isolated.tearDown()
    }

    /// A manager whose favorite has one episode published after the first check.
    private func managerWithOneNewEpisode() async -> NewEpisodesManager {
        let old = makeEpisode("old", pubDate: clock.addingTimeInterval(-86_400))
        feedEpisodes = [old]
        let manager = isolated.newEpisodesManager(favorites: { [unowned self] in [makePodcast(self.feed, title: "Show")] },
                                                  feeds: { [unowned self] _ in self.feedEpisodes },
                                                  now: { [unowned self] in self.clock })
        await manager.refresh()
        clock = clock.addingTimeInterval(3_600)
        feedEpisodes = [makeEpisode("new", pubDate: clock), old]
        clock = clock.addingTimeInterval(60)
        await manager.refresh()
        return manager
    }

    func test_freshEpisodes_showTheEpisodeAndItsPodcast() async {
        let sut = NewEpisodesViewModel(manager: await managerWithOneNewEpisode())

        XCTAssertEqual(sut.freshEpisodes.map(\.episode.title), ["Episode new"])
        XCTAssertEqual(sut.freshEpisodes.first?.podcastTitle, "Show")
        XCTAssertEqual(sut.newCount(for: PodcastViewModel(podcast: makePodcast(feed))), 1)
    }

    func test_markPlayed_takesTheEpisodeOffTheShelf() async throws {
        let sut = NewEpisodesViewModel(manager: await managerWithOneNewEpisode())
        let episode = try XCTUnwrap(sut.freshEpisodes.first?.episode)

        sut.markPlayed(episode)

        XCTAssertTrue(sut.freshEpisodes.isEmpty)
        XCTAssertEqual(sut.newCount(for: PodcastViewModel(podcast: makePodcast(feed))), 0)
    }

    func test_refresh_recordsTheCheck() async {
        let sut = NewEpisodesViewModel(manager: isolated.newEpisodesManager())
        XCTAssertNil(sut.lastRefresh)

        await sut.refresh()

        XCTAssertNotNil(sut.lastRefresh)
        XCTAssertFalse(sut.isRefreshing)
    }
}
