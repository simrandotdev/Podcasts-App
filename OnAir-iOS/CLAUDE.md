# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See also `AGENTS.md` for coding style, test naming, and commit/PR conventions. Some parts of `AGENTS.md` are out of date. Where it disagrees with this file, trust this file: the deployment target is now iOS 16.0, the player XIB, `AppDelegate`, `MainTabBarController`, and launch storyboard have been removed, and controllers and interactors have been replaced by ViewModels and Managers (see Architecture).

## Build & Test

Always build through the workspace. Dependencies come from CocoaPods (FeedKit, Resolver). Persistence uses Core Data and SQLite from the SDK, so there are no Swift packages.

```sh
pod install
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'platform=iOS Simulator,name=<Simulator>' test

# Single test class or method
xcodebuild ... test -only-testing:"Podcasts App Unit Tests/PlaybackManagerTests/test_close_savesProgressAndClearsPlayback"
```

Use the `Podcasts App` scheme for tests. It's the only scheme. There is no lint or format tooling.

## Architecture

The app is SwiftUI-only (`@main` is `Support/PodcastsApp.swift`). It runs on iPhone and iPad. It uses MVVM with the repository pattern, in these layers:

```
View (SwiftUI) → ViewModel (ObservableObject) → Manager → Repository → APIService / CoreDataStack
```

Each layer talks only to the one below it. Views use only ViewModels, never Managers, Repositories or system services. Only Repositories see Core Data. Folders follow the layers: `Presentation Layer/` (views and `ViewModels/`), `Business Layer/` (`Managers/` and `Models/`), and `Data Layers/` (`Repositories/`, `Services/`, `Persistance/`; keep that spelling).

- **ViewModels** are `@MainActor` `ObservableObject`s.
  - Screen ViewModels: `HomeViewModel` (PodcastsScreen), `FavoritesViewModel`, `PodcastDetailViewModel` (EpisodesScreen, one per screen), `HistoryViewModel` (Recently Played, the Home shelf and Downloads), and `SettingsViewModel`. `AppTabView` creates the shared ones and injects them as `environmentObject`s.
  - App-wide feature ViewModels: `PlayerViewModel`, `DownloadsViewModel` and `NewEpisodesViewModel` wrap the app-wide Managers. `PodcastsApp` creates them, and every view that shows playback, downloads or new episodes uses them.
  - They republish their Manager's `objectWillChange`.
  - `PlayerViewModel.play(_:queue:)` resumes an episode that's already loaded rather than reloading it. Screens call `maximizePlayerView(episode, queue)`, which goes through it.
- **Managers** hold business logic and app-wide state.
  - `PodcastsManager` and `EpisodesManager` replaced the old Interactors. They're registered by protocol (`PodcastsManaging`, `EpisodesManaging`) with application scope. They publish `favoritesDidChange` and `historyDidChange` after writes, and the ViewModels reload when they fire.
  - `PlaybackManager`, `DownloadManager` and `NewEpisodesManager` are `@MainActor` singletons (`.shared`). ViewModels take them as optional initializer parameters that default to `.shared`. A default argument of `.shared` warns, because default arguments aren't main-actor isolated.
  - Managers work with the domain models `Podcast` and `Episode`, never with view models.
- **Dependency injection.** Resolver registrations live in `PodcastsApp.swift`, in `registerAllServices()`. Repositories and data Managers are registered there by protocol, and ViewModels resolve them as initializer defaults. Every layer takes its dependencies through its initializer, so tests pass mocks. Shared mocks and helpers (`MockPodcastsManager`, `MockEpisodesManager`, mock repositories, `IsolatedManagers`, `waitUntil`) live in `TestDoubles.swift`.
- **Models and view models.** `Podcast` and `Episode` are plain domain models. Views use `PodcastViewModel` and `EpisodeViewModel` (in `Presentation Layer/ViewModels/`). Conversions back to models, `Podcast(podcastViewModel:)` and `Episode(episodeViewModel:)`, live in extensions in those files.
- **Data sources:**
  - `APIService` searches the iTunes Search API, which returns podcasts that have a `feedUrl`. It fetches episodes by downloading the RSS feed and parsing it with FeedKit (`RSSFeed.toEpisodes()` in `Utility/Extensions`).
  - The "home" list is a search for `PodcastsManager.homeSearchTerm` (`"podcasts"`). Live search kicks in after more than 2 characters, with a 333 ms debounce in `HomeViewModel`.
  - `CoreDataStack` loads `Podcasts.xcdatamodeld` into `Application Support/Podcasts.sqlite`. `FavoritePodcastEntity` holds **favorites**, unique on `rssFeedUrl` and ordered by `favoritedAt` (which numbers the presets). `HistoryEpisodeEntity` holds **listening history**, unique on `streamUrl` and listed newest first by `lastPlayedAt`. Repositories do all work in `CoreDataStack.perform` on background contexts and return domain models; managed objects never leave the closure. The model is loaded once per process (`CoreDataStack.model`). To change the schema, add a new model version and make it current; never edit a shipped version. Lightweight migration upgrades existing stores. Each episode records its podcast's feed URL in `podcastFeedUrl`, which the ON AIR badge matches against `rssFeedUrl`. Old history entries have it as nil.
  - `LegacyDatabaseImporter` runs once when `CoreDataStack.shared` is first used. It moves favorites and history out of the database the app used to keep with GRDB (`Application Support/db.sqlite`), reading it through the SQLite C API. Insertion order becomes `favoritedAt` and `lastPlayedAt`. The old file is deleted only after the import is saved, and rows already in Core Data are never overwritten.
- **Playback.** `PlaybackManager` (`.shared`) owns `AVPlayer`, so playback survives navigation. It handles the queue, the Now Playing session and remote commands, audio-session interruptions, and artwork. It also saves resume positions to `UserDefaults`, keyed by the episode's `streamUrl`. That legacy key must stay as it is so existing users keep their positions. It records history through `EpisodesManaging.saveInHistory`, which triggers `historyDidChange`. For tests, initialize it with `systemPlaybackEnabled: false` and a stub `saveHistory` closure.
- **Downloads.** `DownloadManager.shared` downloads episodes with a background `URLSession`. Views reach it through `DownloadsViewModel`. `AppDelegate` (in `PodcastsApp.swift`) reconnects the session when iOS relaunches the app for download events. `DownloadStore` keeps files in `Application Support/Downloads`, named by a SHA-256 hash of `streamUrl`. Absolute paths are never stored, because the container path can change. Each download has a `<hash>.json` sidecar holding its `Episode`, written when the download starts, which the Downloads tab lists from. Loading a podcast's episodes or the history identifies older downloads that have no sidecar. The "Download on Wi-Fi Only" setting (`DownloadManager.wifiOnlyKey` in `UserDefaults`) sets `allowsCellularAccess` on each new download request. `PlaybackManager` plays the local file when one exists, through its injectable `localFile` closure. For tests, give `DownloadManager` a temporary `DownloadStore` and an ephemeral configuration stubbed with a `URLProtocol`.
- **New episodes.** `NewEpisodesManager.shared` checks the feeds of favorites (presets) for new episodes, through `PodcastsManaging` and `EpisodesManaging`. Views reach it through `NewEpisodesViewModel`. Badges, the Fresh on Air shelf and notifications all come from it. An episode counts as new only if its stream URL wasn't in the feed when the user last opened that podcast *and* it's dated after that visit. Requiring both keeps undated episodes, which FeedKit dates "now", from showing as new. State is stored in `Application Support/NewEpisodes.json`. Opening a podcast (`markSeen`, called by `PodcastDetailViewModel`) clears its new episodes, and playing one from the shelf (`markPlayed`) removes it. Checks run on app launch and foreground (at most every 15 minutes), on pull-to-refresh, and in the background through SwiftUI's `.backgroundTask(.appRefresh(...))`. Its identifier is listed under `BGTaskSchedulerPermittedIdentifiers` in Info.plist. For tests, inject `loadFavorites`, `fetchEpisodes`, a `NewEpisodeNotifying` and `now`.
- **Navigation.** `AppTabView` uses a `NavigationSplitView` sidebar on regular width (iPad) and a `TabView` on compact width. A `MiniPlayerView` sits in a bottom safe-area inset. Tapping it expands to `PlayerDetailsView` as an overlay, capped at 440 pt wide on iPad. Screens get a `maximizePlayerView(episode, queue)` callback to start playback.
- **Episode identity.** Episodes are identified by `streamUrl` everywhere: the queue, history, and resume positions. Don't use titles.

## Testing

- `APIServiceTests` stubs the network by injecting a `URLSession` that uses a custom `URLProtocol` (`PodcastURLProtocol`). Use the same approach for new networking tests; never hit the live network.
- Test repositories against `CoreDataStack(inMemory: true)`. It's still SQLite, so uniqueness constraints apply. Test the legacy import with GRDB-shaped SQLite files built through the SQLite C API (see `LegacyDatabaseImporterTests`).
- Name tests `test_<behavior>_<expectedResult>`.
