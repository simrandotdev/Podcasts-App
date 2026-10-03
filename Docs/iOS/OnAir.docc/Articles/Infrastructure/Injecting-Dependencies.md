# Injecting Dependencies

Wire the layers together with Resolver, and pass dependencies through initializers so each type can be tested on its own.

## Overview

On Air injects dependencies in two ways. Resolver builds the data layer and the data managers, and view models resolve them as initializer defaults. The app-wide managers are main-actor singletons that view models take as optional initializer parameters. Either way, every dependency arrives through an initializer, so tests can pass their own.

![Resolver's registerAllServices registers APIService.shared and CoreDataStack.shared, which feed PodcastsRepository and EpisodesRepository in application scope. Those feed PodcastsManager and EpisodesManager, registered as PodcastsManaging and EpisodesManaging. Separately, PlaybackManager, DownloadManager, and NewEpisodesManager are main-actor singletons. View models resolve the data managers with Resolver.resolve(), and use .shared when no singleton is passed in.](dependency-injection)

### Register Services

`PodcastsApp.swift` registers every service in `registerAllServices()`:

```swift
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // Services and persistence
        register { APIService.shared }
        register { CoreDataStack.shared }
        // Repositories
        register(PodcastsRepositoryProtocol.self) { PodcastsRepository(api: resolve(), store: resolve()) }
            .scope(.application)
        register(EpisodesRepositoryProtocol.self) { EpisodesRepository(api: resolve(), store: resolve()) }
            .scope(.application)
        // Managers. Application scope, so everyone shares their change notifications.
        register(PodcastsManaging.self) { PodcastsManager(repository: resolve()) }
            .scope(.application)
        register(EpisodesManaging.self) { EpisodesManager(repository: resolve()) }
            .scope(.application)
    }
}
```

Repositories and managers are registered by protocol. Application scope gives the whole app one instance of each, which matters for the managers: every view model must subscribe to the same `favoritesDidChange` and `historyDidChange` publishers.

### Resolve Dependencies in View Models

A view model resolves its data managers as default argument values, and takes app-wide managers as optionals that default to `shared`:

```swift
init(episodesManager: EpisodesManaging = Resolver.resolve(),
     downloadManager: DownloadManager? = nil) {
    self.episodesManager = episodesManager
    self.downloadManager = downloadManager ?? .shared
}
```

> Note: A default argument of `.shared` produces a warning, because default arguments aren't isolated to the main actor. Taking an optional and falling back to `.shared` inside the main-actor initializer avoids it.

### Inject Closures for System Services

Types that touch the system take closures or values for those parts, with defaults for the app:

| Type | Injected |
| --- | --- |
| `PlaybackManager` | The `AVPlayer`, `UserDefaults`, whether to use the system audio and Now Playing features, `localFile`, and `saveHistory` |
| `DownloadManager` | The `DownloadStore`, the `URLSessionConfiguration`, `UserDefaults`, and whether to monitor the network |
| `NewEpisodesManager` | The state file URL, `UserDefaults`, `loadFavorites`, `fetchEpisodes`, a `NewEpisodeNotifying` notifier, and `now` |
| `PodcastsRepository` and `EpisodesRepository` | The `APIService`, the `CoreDataStack`, and `now` |
| `LegacyDatabaseImporter` | The database URL and `now` |
| `APIService` | The `URLSession` |

### Add a Dependency

1. Define a protocol for the new type if other layers call it, so tests can replace it.
2. Register it in `registerAllServices()`. Use application scope if it publishes changes or holds state.
3. Add an initializer parameter to each type that uses it, with a default that resolves it.
4. Add a mock to `TestDoubles.swift` when more than one test needs it.

## See Also

- <doc:Architecture>
- <doc:Testing-the-App>
