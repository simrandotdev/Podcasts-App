import XCTest
@testable import Podcasts_Bin

@MainActor
final class HomeViewModelTests: XCTestCase {
    private func makeViewModel(_ manager: MockPodcastsManager = MockPodcastsManager()) -> HomeViewModel {
        HomeViewModel(podcastsManager: manager)
    }

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
}
