# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See also `AGENTS.md` for coding style, test naming, and commit/PR conventions. Some parts of `AGENTS.md` are out of date. Where it disagrees with this file, trust this file: the deployment target is now iOS 16.0, and the player XIB, `AppDelegate`, `MainTabBarController`, and launch storyboard have been removed.

## Build & Test

Always build through the workspace. Dependencies come from two places: CocoaPods (FeedKit, Resolver) and Swift Package Manager (GRDB, pinned in the workspace's `Package.resolved`).

```sh
pod install
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'platform=iOS Simulator,name=<Simulator>' test

# Single test class or method
xcodebuild ... test -only-testing:"Podcasts App Unit Tests/PlaybackControllerTests/test_close_savesProgressAndClearsPlayback"
```

Use the `Podcasts App` scheme for tests. The `Podcasts AppTests` and `PodcastsUITests` schemes reference targets that no longer exist. There is no lint or format tooling.

## Architecture

The app is SwiftUI-only (`@main` is `Support/PodcastsApp.swift`). It runs on iPhone and iPad. Requests flow through these layers:

```
Screen (SwiftUI) → Controller (ObservableObject) → Interactor → Repository → APIService / PersistanceManager
```

- **Dependency injection.** Resolver registrations live in `PodcastsApp.swift`, in `registerAllServices()`. Lower layers get their dependencies through `@Injected`. A type you add must be registered there. `PodcastsController` also has an initializer that takes interactors, which the tests use to inject mocks (`MockPodcastsInteractor` and `MockEpisodesInteractor` live in `PodcastsControllerTests.swift`).
- **Two controller styles.** `PodcastsController` is `@MainActor`, and its interactor returns values directly. `EpisodesController` subscribes to the interactor's `CurrentValueSubject`s (`episodes`, `recentlyPlayedEpisodes`) and maps them into `EpisodeViewModel`s on the main queue.
- **Models and view models.** `Podcast` and `Episode` are GRDB records and are what the data layer uses. Screens use `PodcastViewModel` and `EpisodeViewModel`. Controllers convert between the two using initializers such as `Podcast(podcastViewModel:)` and `Episode(episodeViewModel:)`.
- **Data sources:**
  - `APIService` searches the iTunes Search API, which returns podcasts that have a `feedUrl`. It fetches episodes by downloading the RSS feed and parsing it with FeedKit (`RSSFeed.toEpisodes()` in `Utility/Extensions`).
  - The "home" list is a search for the term `"podcasts"`. Live search kicks in after more than 2 characters, with a 333 ms debounce in `PodcastsController`.
  - `PersistanceManager` (keep this spelling) creates a GRDB SQLite database in Application Support with two tables. The `podcast` table holds **favorites**, keyed by `rssFeedUrl`. The `episode` table holds **listening history**, keyed by `streamUrl`. The schema is defined by `PersistanceManager.migrator` (a GRDB `DatabaseMigrator`). To change it, register a new migration; never edit an existing one. Each episode records its podcast's feed URL in `podcastFeedUrl`, which the ON AIR badge matches against `rssFeedUrl`. History rows saved before that column existed have it as nil.
- **Playback.** `PlaybackController` is a `@MainActor` object that owns `AVPlayer`. It is created once in `PodcastsApp` and passed down as an `environmentObject`, so playback survives navigation. It handles the queue, the Now Playing session and remote commands, audio-session interruptions, and artwork. It also saves resume positions to `UserDefaults`, keyed by the episode's `streamUrl`. That legacy key must stay as it is so existing users keep their positions. When it records history it posts `.playbackHistoryChanged`, and `RecentlyPlayedEpisodesScreen` refreshes when it receives that notification. For tests, initialize it with `systemPlaybackEnabled: false` and a stub `saveHistory` closure.
- **Downloads.** `DownloadManager.shared` downloads episodes with a background `URLSession` and is injected as an `environmentObject`. `AppDelegate` (in `PodcastsApp.swift`) reconnects the session when iOS relaunches the app for download events. `DownloadStore` keeps files in `Application Support/Downloads`, named by a SHA-256 hash of `streamUrl`. Absolute paths are never stored, because the container path can change. Each download has a `<hash>.json` sidecar holding its `Episode`, written when the download starts, which the Downloads tab lists from. The "Download on Wi-Fi Only" setting (`DownloadManager.wifiOnlyKey` in `UserDefaults`) sets `allowsCellularAccess` on each new download request. `PlaybackController` plays the local file when one exists, through its injectable `localFile` closure. For tests, give `DownloadManager` a temporary `DownloadStore` and an ephemeral configuration stubbed with a `URLProtocol`.
- **New episodes.** `NewEpisodeTracker.shared` (an `environmentObject`) checks the feeds of favorites (presets) for new episodes. Badges, the Fresh on Air shelf and notifications all come from it. An episode counts as new only if its stream URL wasn't in the feed when the user last opened that podcast *and* it's dated after that visit. Requiring both keeps undated episodes, which FeedKit dates "now", from showing as new. State is stored in `Application Support/NewEpisodes.json`. Opening a podcast (`markSeen`) clears its new episodes, and playing one from the shelf (`markPlayed`) removes it. Checks run on app launch and foreground (at most every 15 minutes), on pull-to-refresh, and in the background through SwiftUI's `.backgroundTask(.appRefresh(...))`. Its identifier is listed under `BGTaskSchedulerPermittedIdentifiers` in Info.plist. For tests, inject `loadFavorites`, `fetchEpisodes`, a `NewEpisodeNotifying` and `now`.
- **Navigation.** `AppTabView` uses a `NavigationSplitView` sidebar on regular width (iPad) and a `TabView` on compact width. A `MiniPlayerView` sits in a bottom safe-area inset. Tapping it expands to `PlayerDetailsView` as an overlay, capped at 440 pt wide on iPad. Screens get a `maximizePlayerView(episode, queue)` callback to start playback.
- **Episode identity.** Episodes are identified by `streamUrl` everywhere: the queue, history, and resume positions. Don't use titles.

## Testing

- `APIServiceTests` stubs the network by injecting a `URLSession` that uses a custom `URLProtocol` (`PodcastURLProtocol`). Use the same approach for new networking tests; never hit the live network.
- Name tests `test_<behavior>_<expectedResult>`.
