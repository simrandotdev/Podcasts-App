# Discovering Podcasts

Browse trending shows, search for podcasts, and pick up recent listening from the Home tab.

## Overview

The Home tab is `PodcastsScreen`, backed by `HomeViewModel`. It's a single scrolling page with up to three sections:

@Row {
    @Column(size: 2) {
        - term Fresh on Air: New episodes of the user's presets. The shelf appears only when there's something new, and hides during a search. See <doc:Tracking-New-Episodes>.
        - term Recently Played: The ten most recently played episodes, each with a progress bar. The shelf hides during a search. See <doc:Keeping-a-Listening-History>.
        - term Stations: A grid of podcasts. While the user searches, the heading changes to Results and the grid shows search results.
    }
    @Column {
        ![The Home tab, titled On Air, with a search field, the Recently Played shelf, and the first row of station tiles.](screen-home)
    }
}

### Browse Stations

Without a search, the grid shows up to 50 podcasts that are trending now, from the On Air API's `/v1/podcasts/trending`. In builds without the API's address, it shows an iTunes search for "podcasts" instead. See <doc:Loading-Podcasts-and-Feeds>. While the first load runs, the grid shows eight placeholder tiles.

The grid is an adaptive `LazyVGrid` with columns at least 150 points wide, so it shows more columns on iPad. Each `StationTile` shows the artwork with the title and author on a dark band, and two badges in the corner:

- term ON AIR: One of this podcast's episodes is playing. `PlayerViewModel.isOnAir(_:)` compares the playing episode's `podcastFeedUrl` with the podcast's `rssFeedUrl`.
- term NEW: The number of new episodes since the user last opened this podcast, from `NewEpisodesViewModel.newCount(for:)`.

Tapping a tile opens the podcast's page. See <doc:Viewing-a-Podcast>.

### Search for Podcasts

The search field comes from `.searchable(text:)`, bound to `HomeViewModel.searchText`. The view model waits until typing pauses for 333 ms and cancels any search still running. It searches once the trimmed text is longer than 2 characters. Shorter text, including an empty field, brings back the trending stations.

Each request carries an ID, and the view model drops any response that a newer request has replaced. So a slow response never overwrites newer results. If a request fails, the grid shows the error with a Retry button. For the full path of a search request, see <doc:Following-a-Request>.

### Refresh the Page

Pulling to refresh reloads the stations and the listening history, and checks the user's presets for new episodes, all in one gesture.

### Open Episode Cards

The Fresh on Air and Recently Played shelves share one interaction, provided by the `episodeRowActions(play:showDetails:)` modifier:

- A tap plays the episode, or resumes it from its saved position.
- A long press opens `EpisodeDetailsSheet` with the episode's show notes.
- VoiceOver offers both as actions.

## See Also

- <doc:Viewing-a-Podcast>
- <doc:Loading-Podcasts-and-Feeds>
- <doc:Following-a-Request>
