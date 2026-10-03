# Viewing a Podcast

Open a podcast to see its schedule of episodes, tune in to the latest one, or save it as a preset.

## Overview

Tapping a station tile opens `EpisodesScreen`. Each screen creates its own `PodcastDetailViewModel` for that podcast, which loads the episodes from the podcast's RSS feed and tracks whether the podcast is a favorite.

### Read the Station Header

The header shows the artwork, the title, the author in uppercase monospaced type, and the episode count. When one of the podcast's episodes is playing, an ON AIR badge appears and the artwork gets an accent-colored ring.

Two buttons sit below the header. They share a row and stack vertically at large text sizes.

- term Tune In: Plays the latest episode, which is the first one in the feed, with the whole schedule as the queue.
- term Save Preset: Saves the podcast as a favorite. Once saved, it reads Saved Preset, and tapping it again removes the favorite. See <doc:Saving-Presets>.

### Browse the Schedule

The episodes appear as a schedule, in feed order. Each `ScheduleRow` shows:

- The publication date as a month, day, and year block.
- The title, an ON AIR badge while it's playing, and a short summary.
- A progress bar with "x% played" or "Finished", once the episode's length is known.
- A download button. See <doc:Downloading-Episodes>.

A tap plays the episode with the rest of the schedule as its queue, so Up Next and the next-track controls move through the podcast. A long press opens the episode's details.

### Understand What Loading Does

Each time the screen loads, including on pull to refresh, `PodcastDetailViewModel.load()` does more than fetch episodes:

1. It fetches the feed through `EpisodesManaging.fetchEpisodes(forFeedUrl:)`.
2. It passes the episodes to `DownloadManager.identifyDownloads(from:)`, which recovers details for older downloads saved without them.
3. It calls `NewEpisodesManager.markSeen(_:episodeUrls:)`, which clears the podcast's NEW badge and its episodes on the Fresh on Air shelf. See <doc:Tracking-New-Episodes>.
4. It checks whether the podcast is a favorite, to set the Save Preset button.

### Show Episode Details

`EpisodeDetailsSheet` shows the artwork, the title, the progress, and the full show notes. The notes are the feed's HTML description, converted to plain text with `htmlToPlainText()`. The main button reads Play, Resume, or Now Playing, depending on the episode's state, and a second control downloads or removes the episode.

![The episode details sheet, with the episode's artwork and title, a Resume button, and the show notes.](screen-episode-details)

## See Also

- <doc:Saving-Presets>
- <doc:Playing-Episodes>
- <doc:Downloading-Episodes>
