import Combine
import XCTest
@testable import Podcasts_Bin

final class PodcastsManagerTests: XCTestCase {
    private var repository: MockPodcastsRepository!
    private var sut: PodcastsManager!
    private var changes = 0
    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        repository = MockPodcastsRepository()
        sut = PodcastsManager(repository: repository)
        changes = 0
        subscription = sut.favoritesDidChange.sink { [unowned self] in self.changes += 1 }
    }

    func test_fetchPodcasts_searchesForTheHomeTerm() async throws {
        _ = try await sut.fetchPodcasts()
        XCTAssertEqual(repository.searches, [PodcastsManager.homeSearchTerm])
    }

    func test_blankSearch_showsTheHomeList() async throws {
        _ = try await sut.searchPodcasts(forValue: "  \n")
        XCTAssertEqual(repository.searches, ["podcasts"])
    }

    func test_search_usesTheQuery() async throws {
        _ = try await sut.searchPodcasts(forValue: "science")
        XCTAssertEqual(repository.searches, ["science"])
    }

    func test_favoriteAndUnfavorite_saveAndAnnounceTheChange() async throws {
        let podcast = makePodcast()

        try await sut.favorite(podcast: podcast)
        let isFavorite = try await sut.isFavorite(podcast: podcast)
        XCTAssertTrue(isFavorite)
        XCTAssertEqual(changes, 1)

        try await sut.unfavorite(podcast: podcast)
        let favorites = try await sut.fetchFavorites()
        XCTAssertTrue(favorites.isEmpty)
        XCTAssertEqual(changes, 2)
    }

    func test_failedFavorite_throwsWithoutAnnouncingAChange() async {
        repository.shouldFail = true
        do {
            try await sut.favorite(podcast: makePodcast())
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(changes, 0)
        }
    }
}
