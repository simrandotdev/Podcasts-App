import XCTest
@testable import Podcasts_Bin

@MainActor
final class HomeViewModelTests: XCTestCase {
    /// No retry delays by default, so tests never wait.
    private func makeViewModel(_ manager: MockPodcastsManager = MockPodcastsManager(),
                               retryDelays: [TimeInterval] = []) -> HomeViewModel {
        HomeViewModel(podcastsManager: manager, retryDelays: retryDelays)
    }

    private let savedStation = makePodcast("https://example.com/saved", title: "Saved station")

    func test_initialState_hasNoPodcasts() {
        XCTAssertTrue(makeViewModel().podcasts.isEmpty)
    }

    func test_fetchPodcasts_loadsResultsAndEndsLoading() async {
        let sut = makeViewModel()
        await sut.fetchPodcasts()
        XCTAssertEqual(sut.podcasts.count, 1)
        XCTAssertFalse(sut.isLoading)
    }

    func test_failedFetch_exposesErrorAndEndsLoading() async {
        let manager = MockPodcastsManager()
        manager.shouldFail = true
        let sut = makeViewModel(manager)
        await sut.fetchPodcasts()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.podcasts.isEmpty)
    }

    func test_search_usesQueryAndClearingRestoresHome() async {
        let manager = MockPodcastsManager()
        let sut = makeViewModel(manager)
        sut.searchText = "science"
        XCTAssertTrue(sut.isSearching)
        await sut.fetchPodcasts()
        XCTAssertEqual(manager.lastQuery, "science")
        XCTAssertEqual(sut.podcasts.first?.title, "Search result")
        sut.searchText = ""
        await sut.fetchPodcasts()
        XCTAssertEqual(sut.podcasts.first?.title, "Podcast title")
    }

    func test_shortSearch_showsHomeList() async {
        let manager = MockPodcastsManager()
        let sut = makeViewModel(manager)
        sut.searchText = "ab"
        await sut.fetchPodcasts()
        XCTAssertNil(manager.lastQuery)
        XCTAssertEqual(sut.podcasts.first?.title, "Podcast title")
    }

    func test_loadIfNeeded_skipsWhenAlreadyLoaded() async {
        let manager = MockPodcastsManager()
        let sut = makeViewModel(manager)
        await sut.loadIfNeeded()
        manager.shouldFail = true
        await sut.loadIfNeeded()
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.podcasts.count, 1)
    }

    // MARK: - Saved stations

    func test_loadIfNeeded_showsSavedStationsWhenTheLatestCantLoad() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        manager.shouldFail = true
        let sut = makeViewModel(manager)

        await sut.loadIfNeeded()

        XCTAssertEqual(sut.podcasts.map(\.title), ["Saved station"])
        XCTAssertTrue(sut.isShowingSavedStations)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadIfNeeded_replacesSavedStationsWithTheLatest() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        let sut = makeViewModel(manager)

        await sut.loadIfNeeded()

        XCTAssertEqual(sut.podcasts.map(\.title), ["Podcast title"])
        XCTAssertFalse(sut.isShowingSavedStations)
    }

    func test_loadIfNeeded_retriesUntilTheLatestLoad() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        manager.failuresBeforeSuccess = 2
        let sut = makeViewModel(manager, retryDelays: [0, 0, 0])

        await sut.loadIfNeeded()

        XCTAssertEqual(manager.fetchCount, 3)
        XCTAssertEqual(sut.podcasts.map(\.title), ["Podcast title"])
        XCTAssertFalse(sut.isShowingSavedStations)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadIfNeeded_stopsRetryingAfterTheLastDelay() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        manager.shouldFail = true
        let sut = makeViewModel(manager, retryDelays: [0, 0])

        await sut.loadIfNeeded()

        XCTAssertEqual(manager.fetchCount, 3)
        XCTAssertTrue(sut.isShowingSavedStations)
    }

    func test_loadIfNeeded_withoutSavedStationsDoesNotRetry() async {
        let manager = MockPodcastsManager()
        manager.shouldFail = true
        let sut = makeViewModel(manager, retryDelays: [0, 0])

        await sut.loadIfNeeded()

        XCTAssertEqual(manager.fetchCount, 1)
        XCTAssertTrue(sut.podcasts.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadIfNeeded_whileShowingSavedStations_loadsAgain() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        manager.shouldFail = true
        let sut = makeViewModel(manager)
        await sut.loadIfNeeded()

        manager.shouldFail = false
        await sut.loadIfNeeded()

        XCTAssertEqual(sut.podcasts.map(\.title), ["Podcast title"])
        XCTAssertFalse(sut.isShowingSavedStations)
    }

    func test_loadIfNeeded_whileSearching_skipsSavedStations() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        let sut = makeViewModel(manager)
        sut.searchText = "science"

        await sut.loadIfNeeded()

        XCTAssertFalse(sut.isShowingSavedStations)
        XCTAssertEqual(sut.podcasts.map(\.title), ["Search result"])
    }

    func test_search_replacesSavedStations() async {
        let manager = MockPodcastsManager()
        manager.cached = [savedStation]
        manager.shouldFail = true
        let sut = makeViewModel(manager)
        await sut.loadIfNeeded()

        sut.searchText = "science"
        await sut.fetchPodcasts()

        XCTAssertFalse(sut.isShowingSavedStations)
        XCTAssertEqual(sut.podcasts.map(\.title), ["Search result"])
    }
}
