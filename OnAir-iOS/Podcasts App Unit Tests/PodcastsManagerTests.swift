import XCTest
@testable import Podcasts_Bin

final class PodcastsManagerTests: XCTestCase {
    private var repository: MockPodcastsRepository!
    private var sut: PodcastsManager!

    override func setUp() {
        super.setUp()
        repository = MockPodcastsRepository()
        sut = PodcastsManager(repository: repository)
    }

    func test_fetchPodcasts_loadsTrendingPodcasts() async throws {
        let podcasts = try await sut.fetchPodcasts()
        XCTAssertEqual(repository.trendingFetches, 1)
        XCTAssertEqual(repository.searches, [])
        XCTAssertEqual(podcasts.first?.title, "Trending")
    }

    func test_blankSearch_showsTheHomeList() async throws {
        _ = try await sut.searchPodcasts(forValue: "  \n")
        XCTAssertEqual(repository.trendingFetches, 1)
        XCTAssertEqual(repository.searches, [])
    }

    func test_search_usesTheQuery() async throws {
        _ = try await sut.searchPodcasts(forValue: "science")
        XCTAssertEqual(repository.searches, ["science"])
    }

    @MainActor
    func test_favoriteAndUnfavorite_saveAndAnnounceTheChange() async throws {
        let changes = ChangeCounter(sut.favoritesChanges())
        let podcast = makePodcast()

        try await sut.favorite(podcast: podcast)
        let isFavorite = try await sut.isFavorite(podcast: podcast)
        XCTAssertTrue(isFavorite)
        let announcedFavorite = await waitUntil { changes.count == 1 }
        XCTAssertTrue(announcedFavorite)

        try await sut.unfavorite(podcast: podcast)
        let favorites = try await sut.fetchFavorites()
        XCTAssertTrue(favorites.isEmpty)
        let announcedUnfavorite = await waitUntil { changes.count == 2 }
        XCTAssertTrue(announcedUnfavorite)
    }

    @MainActor
    func test_failedFavorite_throwsWithoutAnnouncingAChange() async {
        let changes = ChangeCounter(sut.favoritesChanges())
        repository.shouldFail = true
        do {
            try await sut.favorite(podcast: makePodcast())
            XCTFail("Expected an error")
        } catch {
            let announced = await waitUntil(timeout: 0.2) { changes.count > 0 }
            XCTAssertFalse(announced)
        }
    }
}
