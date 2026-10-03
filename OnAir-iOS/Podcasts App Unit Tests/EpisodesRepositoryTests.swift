import XCTest
@testable import Podcasts_Bin

final class EpisodesRepositoryTests: XCTestCase {
    private var clock = Date(timeIntervalSinceReferenceDate: 700_000_000)
    private var sut: EpisodesRepository!

    override func setUp() {
        super.setUp()
        // History never touches the network; an unstubbed session would fail rather than reach it.
        let api = APIService(session: URLSession(configuration: .ephemeral))
        sut = EpisodesRepository(api: api, store: CoreDataStack(inMemory: true), now: { [unowned self] in
            self.clock = self.clock.addingTimeInterval(1)
            return self.clock
        })
    }

    func test_history_listsTheMostRecentlyPlayedFirst() async throws {
        for id in ["1", "2", "3"] {
            try await sut.saveInHistory(episode: makeEpisode(id))
        }
        let history = try await sut.fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Episode 3", "Episode 2", "Episode 1"])
    }

    func test_playingAgain_movesTheEpisodeToTheTopAndReplacesItsDetails() async throws {
        try await sut.saveInHistory(episode: makeEpisode("1", title: "Old title", podcastFeedUrl: nil))
        try await sut.saveInHistory(episode: makeEpisode("2"))
        try await sut.saveInHistory(episode: makeEpisode("1", title: "New title", podcastFeedUrl: "https://example.com/feed"))

        let history = try await sut.fetchHistory()
        XCTAssertEqual(history.map(\.title), ["New title", "Episode 2"])
        XCTAssertEqual(history.first?.podcastFeedUrl, "https://example.com/feed")
    }

    func test_history_roundTripsEveryDetail() async throws {
        var episode = makeEpisode("1")
        episode.fileUrl = "https://cdn.example.com/1.mp3"
        try await sut.saveInHistory(episode: episode)

        let history = try await sut.fetchHistory()
        let saved = try XCTUnwrap(history.first)
        XCTAssertEqual(saved.title, episode.title)
        XCTAssertEqual(saved.subtitle, episode.subtitle)
        XCTAssertEqual(saved.pubDate, episode.pubDate)
        XCTAssertEqual(saved.description, episode.description)
        XCTAssertEqual(saved.author, episode.author)
        XCTAssertEqual(saved.streamUrl, episode.streamUrl)
        XCTAssertEqual(saved.fileUrl, episode.fileUrl)
        XCTAssertEqual(saved.imageUrl, episode.imageUrl)
        XCTAssertEqual(saved.podcastFeedUrl, episode.podcastFeedUrl)
    }

    func test_historyWithoutFeedUrl_staysNil() async throws {
        try await sut.saveInHistory(episode: makeEpisode("legacy", podcastFeedUrl: nil))
        let saved = try await sut.fetchHistory().first
        XCTAssertNotNil(saved)
        XCTAssertNil(saved?.podcastFeedUrl)
    }

    func test_episodeWithoutStreamUrl_isNotSaved() async throws {
        let episode = Episode(title: "No audio", subtitle: "", pubDate: Date(), description: "", author: "", streamUrl: "")
        do {
            try await sut.saveInHistory(episode: episode)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? PersistenceError, .missingIdentifier)
        }
        let history = try await sut.fetchHistory()
        XCTAssertTrue(history.isEmpty)
    }

    func test_fetchEpisodes_withoutFeed_returnsNothing() async throws {
        let episodes = try await sut.fetchEpisodes(forFeedUrl: "")
        XCTAssertTrue(episodes.isEmpty)
    }
}
