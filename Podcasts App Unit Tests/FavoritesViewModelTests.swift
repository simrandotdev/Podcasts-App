import XCTest
@testable import Podcasts_Bin

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    func test_fetchFavorites_loadsPresetsInOrder() async {
        let manager = MockPodcastsManager()
        manager.favorites = [makePodcast("https://example.com/a", title: "A"), makePodcast("https://example.com/b", title: "B")]
        let sut = FavoritesViewModel(podcastsManager: manager)

        await sut.fetchFavorites()

        XCTAssertEqual(sut.favorites.map(\.title), ["A", "B"])
        XCTAssertFalse(sut.isEmpty)
    }

    func test_isEmpty_onlyAfterTheFirstLoad() async {
        let sut = FavoritesViewModel(podcastsManager: MockPodcastsManager())
        XCTAssertFalse(sut.isEmpty)
        await sut.fetchFavorites()
        XCTAssertTrue(sut.isEmpty)
    }

    func test_favoriteChangedElsewhere_reloads() async {
        let manager = MockPodcastsManager()
        let sut = FavoritesViewModel(podcastsManager: manager)
        await sut.fetchFavorites()

        manager.favorites = [makePodcast(title: "Saved on another screen")]
        manager.sendFavoritesDidChange()

        let reloaded = await waitUntil { sut.favorites.map(\.title) == ["Saved on another screen"] }
        XCTAssertTrue(reloaded)
    }

    func test_failedFetch_exposesErrorAndKeepsEmptyStateHidden() async {
        let manager = MockPodcastsManager()
        manager.shouldFail = true
        let sut = FavoritesViewModel(podcastsManager: manager)

        await sut.fetchFavorites()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isEmpty)
    }
}
