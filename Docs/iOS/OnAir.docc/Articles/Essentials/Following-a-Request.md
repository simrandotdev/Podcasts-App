# Following a Request

Trace a search and a play action through every layer of the app.

## Overview

The clearest way to see the architecture at work is to follow one request from a view down to its data source and back. This article traces two: searching for a podcast, and playing an episode.

### Search for a Podcast

A search starts in the Home tab's search field and ends with the station grid showing results.

![A sequence diagram. PodcastsScreen sends searchText to HomeViewModel, which waits 333 milliseconds and needs at least 3 characters. HomeViewModel calls PodcastsManager, which calls PodcastsRepository, which calls APIService, which sends a GET request to the On Air API. The JSON results return to APIService, which skips results without a feed URL. An array of Podcast values returns through each layer to HomeViewModel, which stores the podcasts that PodcastsScreen observes.](search-sequence)

1. `PodcastsScreen` binds its `.searchable` field to `HomeViewModel.searchText`.
2. `HomeViewModel` debounces the text. It ignores the initial value and repeated values, waits 333 ms after typing stops, and cancels any search still in flight.
3. If the trimmed text is longer than 2 characters, the view model calls `PodcastsManager.searchPodcasts(forValue:)`. Otherwise it calls `fetchPodcasts()`, which loads trending podcasts.
4. `PodcastsManager` calls `PodcastsRepository.search(forValue:)`, which calls `APIService.fetchPodcastsAsync(searchText:)`.
5. `APIService` requests `/v1/search` from the On Air API, which searches Podcast Index. In builds without the API's address, it requests `https://itunes.apple.com/search` instead. It decodes the response, skips results without a feed URL, and removes repeated feeds. It returns `[Podcast]`.
6. Back in `HomeViewModel`, a request ID discards responses that a newer search has replaced. The view model maps the results to `PodcastViewModel` values and stores them, and because the grid observes them, it redraws under a Results heading.

### Play an Episode

Playback starts when the user taps an episode row and ends with the player running and the history updated.

![A sequence diagram. EpisodesScreen calls maximizePlayerView on AppTabView, which expands the player and calls play on PlayerViewModel. PlayerViewModel resumes an episode that's already loaded, or calls load on PlaybackManager. PlaybackManager asks DownloadStore for a downloaded file, replaces the AVPlayer's current item, seeks to the saved position, and calls saveInHistory on EpisodesManager, which announces the change. AVPlayer reports the time every second, and PlayerViewModel observes PlaybackManager's changes.](playback-sequence)

1. The row calls the screen's `maximizePlayerView(episode, queue)` closure with the tapped episode and the list it came from, which becomes the queue.
2. `AppTabView` calls `PlayerViewModel.play(_:queue:)` and expands the player.
3. If that episode is already loaded, `PlayerViewModel` resumes it. Otherwise it converts the display models back to `Episode` values and calls `PlaybackManager.load(_:queue:autoplay:)`.
4. `PlaybackManager` saves the position of the episode it's leaving, then looks for a downloaded copy with `DownloadStore.existingFile(for:)`. It plays that file when there is one, and streams the episode otherwise.
5. It replaces the `AVPlayer` item and, once the item is ready, seeks to the position saved for that `streamUrl`.
6. It records the play through `EpisodesManaging.saveInHistory(episode:)`. The repository updates or inserts the history row with the current date, and `EpisodesManager` announces the change through `historyChanges()`, so `HistoryViewModel` reloads Recently Played.
7. While the episode plays, a periodic time observer runs every second. It updates the position, saves it, and counts listening time. The player and mini player read the position through `PlayerViewModel`, so Observation redraws them.

## See Also

- <doc:Architecture>
- <doc:Discovering-Podcasts>
- <doc:Playing-Episodes>
