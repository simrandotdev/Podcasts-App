import XCTest
import Combine
@testable import Podcasts_Bin

@MainActor
final class PodcastsControllerTests: XCTestCase {
    private func makeController(_ interactor: MockPodcastsInteractor = MockPodcastsInteractor()) -> PodcastsController {
        PodcastsController(podcastsInteractor: interactor, episodesInteractor: MockEpisodesInteractor())
    }

    func test_initialState_hasNoPodcasts() {
        XCTAssertTrue(makeController().podcasts.isEmpty)
    }

    func test_fetchPodcasts_loadsResultsAndEndsLoading() async {
        let sut = makeController()
        await sut.fetchPodcasts()
        XCTAssertEqual(sut.podcasts.count, 1)
        XCTAssertFalse(sut.isLoading)
    }

    func test_failedFetch_exposesErrorAndEndsLoading() async {
        let interactor = MockPodcastsInteractor()
        interactor.shouldFail = true
        let sut = makeController(interactor)
        await sut.fetchPodcasts()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.podcasts.isEmpty)
    }

    func test_search_usesQueryAndClearingRestoresHome() async {
        let interactor = MockPodcastsInteractor()
        let sut = makeController(interactor)
        sut.searchText = "science"
        await sut.fetchPodcasts()
        XCTAssertEqual(interactor.lastQuery, "science")
        XCTAssertEqual(sut.podcasts.first?.title, "Search result")
        sut.searchText = ""
        await sut.fetchPodcasts()
        XCTAssertEqual(sut.podcasts.first?.title, "Podcast title")
    }

    func test_favoriteChanges_refreshOnlyFavorites() async {
        let interactor = MockPodcastsInteractor()
        let sut = makeController(interactor)
        await sut.fetchPodcasts()
        let podcast = sut.podcasts[0]
        await sut.favorite(podcast: podcast)
        XCTAssertEqual(sut.favoritePodcasts.count, 1)
        let isFavorite = await sut.isfavorite(podcast: podcast)
        XCTAssertTrue(isFavorite)
        XCTAssertFalse(sut.isLoading)
        await sut.unfavorite(podcast: podcast)
        XCTAssertTrue(sut.favoritePodcasts.isEmpty)
        XCTAssertEqual(sut.podcasts.count, 1)
    }
}

final class MockPodcastsInteractor: PodcastsInteractable {
    var shouldFail = false
    var lastQuery: String?
    var favorites: [Podcast] = []
    private let podcast = Podcast(recordId: "1", title: "Podcast title", author: "Author",
                                  image: "", totalEpisodes: 1, rssFeedUrl: "https://example.com/feed")

    func fetchPodcasts() async throws -> [Podcast] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return [podcast]
    }

    func searchPodcasts(forValue value: String) async throws -> [Podcast] {
        lastQuery = value
        return [Podcast(recordId: "2", title: "Search result", author: "Author", image: "",
                        totalEpisodes: 1, rssFeedUrl: "https://example.com/search")]
    }

    func favorite(podcast: Podcast) async throws -> [Podcast] {
        favorites = [podcast]
        return [self.podcast]
    }

    func unfavorite(podcast: Podcast) async throws -> [Podcast] {
        favorites = []
        return [self.podcast]
    }

    func isFavorite(podcast: Podcast) async throws -> Bool { !favorites.isEmpty }
    func fetchFavorites() async throws -> [Podcast] { favorites }
}

final class MockEpisodesInteractor: EpisodesInteractable {
    var episodes = CurrentValueSubject<[Episode], Never>([])
    var recentlyPlayedEpisodes = CurrentValueSubject<[Episode], Never>([])
    func fetchEpisodes(forPodcast podcast: Podcast) async throws {}
    func searchEpisodes(forValue value: String) async throws {}
    func saveInHistory(episode: Episode) async throws {}
    func fetchEpisodesFromHistory() async throws {}
}
