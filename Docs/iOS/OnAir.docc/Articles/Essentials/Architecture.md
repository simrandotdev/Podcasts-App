# Architecture

Learn how On Air divides its work into layers, and the rules that keep those layers independent.

## Overview

On Air uses the Model-View-ViewModel (MVVM) pattern with repositories. A request travels down through the layers, and each layer calls only the layer directly below it. Views never reach past their view models, and only repositories know that Core Data exists.

![Six stacked layers, each listing its main types. Views call view models, view models call managers, managers call repositories, repositories call services, and services use Apple frameworks and remote data.](architecture-layers)

The source folders follow the layers:

```
OnAir-iOS/Podcasts App/
├── Source/
│   ├── Presentation Layer/   Views, the player, shared UI, and ViewModels/
│   ├── Business Layer/       Managers/ and Models/
│   ├── Data Layers/          Repositories/, Services/, and Persistance/
│   └── Utility/              Extensions and logging
└── Support/                  PodcastsApp.swift, Info.plist, and assets
```

> Note: The persistence folder is spelled `Persistance`. Keep that spelling, because the Xcode project refers to it by name.

#### Views

Views are SwiftUI structures that draw state and forward user actions. A view reads only view models, which it receives as environment objects or creates as state objects. It never calls a manager, a repository, or a system service.

Screens that start playback don't hold the player. `AppTabView` passes each one a `maximizePlayerView(episode, queue)` closure, which starts the episode and expands the player.

#### View Models

View models are `@MainActor` classes that conform to `ObservableObject`. They load data through managers, convert domain models into display models, and publish the result. There are two kinds.

Screen view models back one screen, or a few screens that show the same data:

| View model | Used by |
| --- | --- |
| `HomeViewModel` | `PodcastsScreen`, the Home tab |
| `FavoritesViewModel` | `FavoritesScreen` |
| `HistoryViewModel` | `RecentlyPlayedEpisodesScreen`, the Home tab's Recently Played shelf, and `DownloadsScreen` |
| `PodcastDetailViewModel` | `EpisodesScreen`, one per podcast |
| `SettingsViewModel` | `SettingsView` |

`AppTabView` creates the first three and shares them with every screen. Each `EpisodesScreen` and the `SettingsView` create their own.

App-wide view models wrap the managers that own long-lived state. `PodcastsApp` creates them once and puts them in the environment, so every view that shows playback, downloads, or new episodes shares them:

- term `PlayerViewModel`: Wraps `PlaybackManager`. Provides the current episode, the queue, the position, the speed, and the playback controls.
- term `DownloadsViewModel`: Wraps `DownloadManager`. Provides download states, the library of downloads, and storage use.
- term `NewEpisodesViewModel`: Wraps `NewEpisodesManager`. Provides the Fresh on Air shelf, NEW counts, and the alert setting.

Views use display models rather than domain models. `PodcastViewModel` and `EpisodeViewModel` hold the fields a view shows, plus formatted values such as `numberOfEpisodes` and `formattedDateString`. When a view model hands an item back to a manager, it converts it with `Podcast(podcastViewModel:)` or `Episode(episodeViewModel:)`.

#### Managers

Managers hold business logic and app-wide state. They work only with the domain models `Podcast` and `Episode`, never with display models.

- term Data managers: `PodcastsManager` and `EpisodesManager` coordinate the repositories. Resolver registers them by protocol, as `PodcastsManaging` and `EpisodesManaging`, in application scope. The whole app shares one instance of each, so every view model hears the same change events.
- term App-wide managers: `PlaybackManager`, `DownloadManager`, and `NewEpisodesManager` are `@MainActor` singletons, reached through `shared`. Each owns something that must outlive any screen: the `AVPlayer`, the background `URLSession`, and the new-episode tracking state.

#### Repositories and Stores

`PodcastsRepository` and `EpisodesRepository` sit behind protocols, `PodcastsRepositoryProtocol` and `EpisodesRepositoryProtocol`, and they're the only types that touch Core Data. Every query runs inside `CoreDataStack.perform(_:)` on a background context and returns domain models. Managed objects never leave the closure.

Two smaller stores sit at the same level. `DownloadStore` names, finds, and deletes downloaded files. `ListeningStats` records listening time per day in `UserDefaults`.

#### Services

`APIService` finds podcasts through the On Air API, or the iTunes Search API when the On Air API isn't configured, and downloads RSS feeds. `CoreDataStack` owns the persistent container. `LegacyDatabaseImporter` moves favorites and history out of the database that earlier versions of the app kept. For details, see <doc:Loading-Podcasts-and-Feeds> and <doc:Storing-Data>.

### Identify Podcasts and Episodes by URL

A podcast's identity is its RSS feed URL, `rssFeedUrl`. An episode's identity is its audio URL, `streamUrl`. Favorites, the history, downloads, the playback queue, resume positions, and new-episode tracking all key on these values. Titles aren't unique, so the app never uses them as identifiers.

> Important: `PlaybackManager` saves resume positions in `UserDefaults` under the bare `streamUrl`. Keep that key unchanged so existing users keep their positions.

### Propagate Changes

Writes travel down through the layers. Changes come back up in one of two ways, depending on which object owns the state.

![Three columns. On the left, a write goes from EpisodesScreen through PodcastDetailViewModel, PodcastsManager, and PodcastsRepository to CoreDataStack. In the middle, PodcastsManager sends favoritesDidChange to FavoritesViewModel, which updates FavoritesScreen. On the right, PlaybackManager's published state reaches PlayerViewModel and then the player views through objectWillChange.](state-propagation)

**Change events.** After `PodcastsManager` saves or removes a favorite, it sends `favoritesDidChange`. After `EpisodesManager` records a play, it sends `historyDidChange`. Each subscribed view model moves to the main queue with `receive(on:)` and reloads. That's how saving a preset on a podcast's page updates the Favorites tab, and how playing an episode anywhere updates Recently Played.

**Republished state.** The app-wide managers are observable objects. Their view models forward the manager's `objectWillChange`, so a view that observes `PlayerViewModel` redraws whenever `PlaybackManager` publishes a new position, and the same holds for downloads and new episodes. Where views need display models, the view model maps the manager's published value. For example, `PlayerViewModel` maps `PlaybackManager.$episode` into an `EpisodeViewModel`.

### Use Concurrency Safely

- View models and the app-wide managers run on the main actor.
- Repository methods are `async`. Core Data work runs on a new background context for each call. Its merge policy, `NSMergeByPropertyObjectTrumpMergePolicy`, updates a row that another context saved at the same time rather than duplicating it.
- `APIService` parses feeds inside its `async` methods, off the main actor.
- `DownloadSessionDelegate` receives `URLSession` callbacks on the session's queue and forwards them to `DownloadManager` on the main actor.
- `PlaybackManager` chains history writes, so episodes chosen in quick succession are recorded in order.

## See Also

- <doc:Following-a-Request>
- <doc:Injecting-Dependencies>
- <doc:Navigating-the-App>
