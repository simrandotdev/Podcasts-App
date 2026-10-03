import XCTest
@testable import Podcasts_Bin

final class PodcastsRepositoryTests: XCTestCase {
    private var clock = Date(timeIntervalSinceReferenceDate: 700_000_000)
    private var sut: PodcastsRepository!

    override func setUp() {
        super.setUp()
        // Favorites never touch the network; an unstubbed session would fail rather than reach it.
        let api = APIService(session: URLSession(configuration: .ephemeral))
        sut = PodcastsRepository(api: api, store: CoreDataStack(inMemory: true), now: { [unowned self] in
            self.clock = self.clock.addingTimeInterval(1)
            return self.clock
        })
    }

    func test_favorites_areListedInTheOrderTheyWereSaved() async throws {
        for feed in ["https://example.com/c", "https://example.com/a", "https://example.com/b"] {
            try await sut.favorite(podcast: makePodcast(feed))
        }
        let favorites = try await sut.fetchFavoritePodcasts()
        XCTAssertEqual(favorites.map(\.rssFeedUrl), ["https://example.com/c", "https://example.com/a", "https://example.com/b"])
    }

    func test_favoritingAgain_updatesDetailsAndKeepsThePresetNumber() async throws {
        try await sut.favorite(podcast: makePodcast("https://example.com/a", title: "Old title"))
        try await sut.favorite(podcast: makePodcast("https://example.com/b"))
        try await sut.favorite(podcast: makePodcast("https://example.com/a", title: "New title"))

        let favorites = try await sut.fetchFavoritePodcasts()
        XCTAssertEqual(favorites.map(\.rssFeedUrl), ["https://example.com/a", "https://example.com/b"])
        XCTAssertEqual(favorites.first?.title, "New title")
    }

    func test_unfavorite_removesOnlyThatPodcast() async throws {
        let kept = makePodcast("https://example.com/kept")
        let removed = makePodcast("https://example.com/removed")
        try await sut.favorite(podcast: kept)
        try await sut.favorite(podcast: removed)

        try await sut.unfavorite(podcast: removed)

        let isKept = try await sut.isFavorite(podcast: kept)
        let isRemoved = try await sut.isFavorite(podcast: removed)
        XCTAssertTrue(isKept)
        XCTAssertFalse(isRemoved)
    }

    func test_favorite_roundTripsEveryDetail() async throws {
        let podcast = Podcast(recordId: "42", title: "Title", author: "Author", image: "https://example.com/art.jpg",
                              totalEpisodes: nil, rssFeedUrl: "https://example.com/feed")
        try await sut.favorite(podcast: podcast)

        let saved = try await sut.fetchFavoritePodcasts().first
        XCTAssertEqual(saved?.recordId, "42")
        XCTAssertEqual(saved?.title, "Title")
        XCTAssertEqual(saved?.author, "Author")
        XCTAssertEqual(saved?.image, "https://example.com/art.jpg")
        XCTAssertNil(saved?.totalEpisodes)
        XCTAssertEqual(saved?.rssFeedUrl, "https://example.com/feed")
    }

    func test_podcastWithoutFeed_cantBeFavorited() async throws {
        let podcast = makePodcast("")
        do {
            try await sut.favorite(podcast: podcast)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? PersistenceError, .missingIdentifier)
        }
        let isFavorite = try await sut.isFavorite(podcast: podcast)
        XCTAssertFalse(isFavorite)
    }
}
