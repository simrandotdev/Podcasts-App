# Saving Presets

Keep favorite podcasts as numbered presets, like the preset buttons on a radio.

## Overview

The Favorites tab is `FavoritesScreen`, backed by `FavoritesViewModel`. It shows the user's favorite podcasts as station tiles labeled P1, P2, and so on, in the order the user saved them. Presets are also the podcasts that On Air watches for new episodes.

@Row {
    @Column(size: 2) {
        Each tile carries the same badges as on the Home tab: ON AIR while one of the podcast's episodes is playing, and NEW with a count of new episodes. Tapping a tile opens the podcast's page.

        Before the user saves anything, the tab shows a "No presets yet" message that explains how to add one. The view model's `hasLoaded` flag keeps that message from flashing while the first load runs.

        Pulling to refresh reloads the favorites and checks every preset for new episodes.
    }
    @Column {
        ![The Favorites tab, showing six presets numbered P1 to P6.](screen-favorites)
    }
}

### Save and Remove a Preset

The user saves a preset with the Save Preset button on a podcast's page. The request takes this path:

1. `PodcastDetailViewModel.toggleFavorite()` converts its `PodcastViewModel` to a `Podcast` and calls `PodcastsManaging.favorite(podcast:)` or `unfavorite(podcast:)`.
2. `PodcastsRepository` saves a `FavoritePodcastEntity` keyed by `rssFeedUrl`, or deletes it.
3. `PodcastsManager` sends `favoritesDidChange`.
4. `FavoritesViewModel` reloads, so the Favorites tab updates even though the user changed it from another screen.

### Number the Presets

Each favorite stores the date it was first saved, `favoritedAt`, and the repository lists favorites in that order. A preset's number is its position in the list. Saving a podcast that's already a favorite updates its details but keeps its date, so its number doesn't change. Removing a preset moves the presets after it up by one.

> Note: Favorites saved by earlier versions of the app had no dates. `LegacyDatabaseImporter` gives them dates one second apart, in their original order, so they keep their numbers. See <doc:Storing-Data>.

## See Also

- <doc:Viewing-a-Podcast>
- <doc:Tracking-New-Episodes>
- <doc:Storing-Data>
