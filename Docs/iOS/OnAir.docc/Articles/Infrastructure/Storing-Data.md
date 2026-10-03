# Storing Data

Keep favorites and history in Core Data, downloads and tracking state in files, and small values in user defaults.

## Overview

On Air stores each kind of data where its owner can read it most simply. Records the app queries and sorts go in Core Data. Files and state that belong to one manager go in Application Support. Small values go in `UserDefaults`.

![Three groups. Application Support holds Podcasts.sqlite for favorites and history, the Downloads folder, NewEpisodes.json, and the old db.sqlite, which is imported once and then deleted. UserDefaults holds resume positions keyed by stream URL, episode durations, the playback rate, listening time per day, and two settings. URLCache.shared holds artwork, up to 50 megabytes in memory and 200 on disk.](storage-map)

### Model Favorites and History

The Core Data model, `Podcasts.xcdatamodeld`, has two entities and no relationships.

![Two entities. FavoritePodcastEntity has a unique rssFeedUrl, a favoritedAt date for preset order, and optional recordId, title, author, image, and totalEpisodes. HistoryEpisodeEntity has a unique streamUrl, a lastPlayedAt date for newest-first order, and title, subtitle, pubDate, episodeDescription, author, fileUrl, imageUrl, and podcastFeedUrl. A dashed line links podcastFeedUrl to rssFeedUrl for the ON AIR match. Each entity converts to and from a domain model: Podcast and Episode.](core-data-model)

- term FavoritePodcastEntity: A favorite, or preset. It has a uniqueness constraint on `rssFeedUrl`, and the repository sorts favorites by `favoritedAt`, oldest first, which numbers the presets.
- term HistoryEpisodeEntity: An episode in the listening history. It has a uniqueness constraint on `streamUrl`, and the repository sorts the history by `lastPlayedAt`, newest first. The episode's description is stored as `episodeDescription`, because `NSManagedObject` already defines `description`.

The two entities aren't related in the model. A history entry's `podcastFeedUrl` matches a favorite's `rssFeedUrl` by value, which is how the ON AIR badge finds the station that's playing.

Each entity converts to and from its domain model. `update(from:)` copies a `Podcast` or `Episode` into the entity, and the `podcast` and `episode` properties build the domain model back. `FavoritePodcastEntity.update(from:)` leaves `favoritedAt` alone, so saving an existing favorite keeps its preset number.

### Use the Core Data Stack

`CoreDataStack.shared` loads the model into `Application Support/Podcasts.sqlite`.

- It loads the model once per process, as `CoreDataStack.model`. Two loaded copies of the same model would both claim the entity classes.
- Its store description turns on automatic lightweight migration.
- `perform(_:)` runs a closure on a new background context and saves any changes. Its merge policy updates a row that another context saved at the same time instead of failing on the uniqueness constraint.
- `performAndWait(_:)` is the blocking version, for work that must finish before the stack is used.
- `CoreDataStack(inMemory: true)` keeps the store at `/dev/null` for tests. It's still SQLite, so uniqueness constraints behave as they do on disk.

Only the repositories call the stack, and managed objects never leave the closures they're fetched in. Everything above the repositories sees `Podcast` and `Episode`.

### Change the Schema

To change the model, add a new model version and make it current. Lightweight migration upgrades existing stores to it.

> Important: Never edit a model version that has shipped. Existing stores were created from it, and Core Data needs the original to migrate them.

### Import the Legacy Database

Earlier versions of On Air kept favorites and history in a GRDB database at `Application Support/db.sqlite`. `LegacyDatabaseImporter` moves that data into Core Data once, the first time `CoreDataStack.shared` is used.

1. It reads the old `podcast` and `episode` tables through the SQLite C API, in insertion order. A missing table counts as empty.
2. Because the old tables had no dates, it gives each row a date one second apart, oldest first and all in the past. Favorites keep their preset numbers, and the history keeps its order.
3. It skips any row whose feed URL or stream URL is already in Core Data, so it never duplicates or overwrites data.
4. It deletes the old file and its `-wal`, `-shm`, and `-journal` companions only after the import is saved. If anything fails, the file stays, and the import runs again on the next launch.

History saved before the app recorded feed URLs keeps a `nil` `podcastFeedUrl`.

### Keep Small Values in User Defaults

| Key | Owner | Value |
| --- | --- | --- |
| The episode's `streamUrl` | `PlaybackManager` | The resume position, in seconds |
| `duration:` followed by the `streamUrl` | `PlaybackManager` | The episode's length, in seconds |
| `playbackRate` | `PlaybackManager` | 1, 1.25, 1.5, or 2 |
| `listeningSecondsByDay` | `ListeningStats` | Seconds of listening, keyed by `yyyy-MM-dd` |
| `downloadsWiFiOnly` | `DownloadManager` | The Download on Wi-Fi Only setting |
| `newEpisodeNotificationsEnabled` | `NewEpisodesManager` | The New Episode Alerts setting |
| `isUserSubscribed` | `Constants.InAppSubscribed` | A flag set from the Debug section in debug builds |

### Store Files

- `Application Support/Downloads` holds downloaded audio and a JSON sidecar for each episode. See <doc:Downloading-Episodes>.
- `Application Support/NewEpisodes.json` holds the new-episode tracking state. See <doc:Tracking-New-Episodes>.

## See Also

- <doc:Architecture>
- <doc:Keeping-a-Listening-History>
- <doc:Testing-the-App>
