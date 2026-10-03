# Testing the App

Run the unit tests, and use the seams each layer provides for test doubles.

## Overview

The Podcasts App Unit Tests target holds XCTest unit tests, hosted by the app and run with the Podcasts App scheme. Tests import the app module with `@testable import Podcasts_Bin`. For the commands, see <doc:Building-and-Running>.

Two rules apply to every test:

- Name tests `test_<behavior>_<expectedResult>`, such as `test_fetchFavorites_loadsPresetsInOrder`.
- Never reach the live network. Stub it with a `URLProtocol`, as `APIServiceTests` does with `PodcastURLProtocol`.

### Use the Shared Test Doubles

`TestDoubles.swift` holds the helpers that more than one test file uses:

| Helper | Purpose |
| --- | --- |
| `makePodcast(_:title:totalEpisodes:)` and `makeEpisode(_:title:pubDate:podcastFeedUrl:)` | Build domain models with sensible defaults |
| `MockPodcastsManager` and `MockEpisodesManager` | Stand in for the data managers. Set `shouldFail` to simulate errors, and send change events on demand |
| `MockPodcastsRepository` and `MockEpisodesRepository` | Stand in for the repositories |
| `SilentNotifier` | A `NewEpisodeNotifying` that never notifies |
| `IsolatedManagers` | Builds app-wide managers on a temporary directory and a private `UserDefaults` suite. Call `tearDown()` when done |
| `waitUntil(timeout:_:)` | Waits for state that updates asynchronously, such as a reload after a change event |

A view model test passes a mock to the view model's initializer, acts, and checks the published state:

```swift
@MainActor
final class FavoritesViewModelTests: XCTestCase {
    func test_favoriteChangedElsewhere_reloads() async {
        let manager = MockPodcastsManager()
        let sut = FavoritesViewModel(podcastsManager: manager)
        await sut.fetchFavorites()

        manager.favorites = [makePodcast(title: "Saved on another screen")]
        manager.sendFavoritesDidChange()

        let reloaded = await waitUntil { sut.favorites.map(\.title) == ["Saved on another screen"] }
        XCTAssertTrue(reloaded)
    }
}
```

### Test Each Layer

| Type | How to isolate it |
| --- | --- |
| View models | Pass mock managers. For app-wide managers, pass instances from `IsolatedManagers` |
| `PodcastsRepository` and `EpisodesRepository` | Use `CoreDataStack(inMemory: true)`, and inject `now` to control dates |
| `LegacyDatabaseImporter` | Build GRDB-shaped SQLite files with the SQLite C API, as `LegacyDatabaseImporterTests` does |
| `APIService` | Inject a `URLSession` whose configuration uses `PodcastURLProtocol` |
| `PlaybackManager` | Pass `systemPlaybackEnabled: false` and a stub `saveHistory` closure, plus private `UserDefaults` |
| `DownloadManager` | Pass a temporary `DownloadStore`, an ephemeral configuration stubbed with a `URLProtocol`, and `monitorsNetwork: false` |
| `NewEpisodesManager` | Inject `loadFavorites`, `fetchEpisodes`, a `NewEpisodeNotifying` notifier, and `now` |
| `ListeningStats` and `ListeningHeatmap` | Pass private `UserDefaults`, a fixed calendar, and fixed dates |

> Tip: With `systemPlaybackEnabled: false`, `PlaybackManager` leaves the audio session, Now Playing, and remote commands alone, so a test can't change the simulator's audio state.

## See Also

- <doc:Injecting-Dependencies>
- <doc:Building-and-Running>
