# Keeping a Listening History

Record every episode the user plays, and resume any of them from the broadcast log.

## Overview

On Air records an episode in the listening history each time it loads in the player. The history appears in two places: the Recently Played tab, styled as a station's broadcast log, and the Recently Played shelf on the Home tab, which shows the ten most recent episodes. Both read from `HistoryViewModel`, which `AppTabView` creates and shares.

@Row {
    @Column(size: 2) {
        Each entry in the broadcast log shows the artwork, the author, the title, a progress bar, the publication date, and a download button. The entry that's playing gets an ON AIR badge and an accent-colored border.

        - A tap resumes the episode from its saved position, with the rest of the history as the queue.
        - A long press opens the episode's details.
        - Pulling to refresh reloads the history.

        Before the user plays anything, the tab shows "Nothing on the log yet".
    }
    @Column {
        ![The Recently Played tab, with the Broadcast Log heading and a list of episodes with progress bars.](screen-history)
    }
}

### Record a Play

When `PlaybackManager` loads an episode, it calls its `saveHistory` closure, which by default resolves `EpisodesManaging` and calls `saveInHistory(episode:)`.

1. `EpisodesRepository` looks for a `HistoryEpisodeEntity` with the episode's `streamUrl`. It updates that row if it exists, and inserts one otherwise.
2. It sets `lastPlayedAt` to now, so playing an episode again moves it to the top.
3. `EpisodesManager` announces the change through `historyChanges()`, and `HistoryViewModel` reloads.

`PlaybackManager` waits for each history write to finish before starting the next, so episodes chosen in quick succession are recorded in the order they were played. If a write fails, the player shows the error.

### Read the History

`EpisodesRepository.fetchHistory()` returns the whole history, most recently played first. After loading it, `HistoryViewModel` passes the episodes to `DownloadManager.identifyDownloads(from:)`, which recovers details for downloads saved before the app recorded them. See <doc:Downloading-Episodes>.

### Match History to Podcasts

Each history entry stores its podcast's feed URL in `podcastFeedUrl`, which is how the ON AIR badge knows which station is playing. Entries saved before that field existed have no feed URL. To cover them, a podcast's page also matches the playing episode against the podcast's own episodes by `streamUrl`.

## See Also

- <doc:Playing-Episodes>
- <doc:Storing-Data>
- <doc:Discovering-Podcasts>
