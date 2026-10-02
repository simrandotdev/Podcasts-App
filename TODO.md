# TODO

Feature ideas for the Podcasts app, grouped roughly by value for effort.

Several items refer to the radio-style UI (station tiles, presets, broadcast log, schedule, ON AIR badge) that lives on the `recently-played-row` branch.

## Quick wins

- [ ] **Playback speed** (1×, 1.25×, 1.5×, 2×). Set `AVPlayer.rate` in `PlaybackController` and add a "SPEED" control to the player.
- [ ] **Sleep timer** (15, 30 or 60 minutes, or end of episode). Add a timer in `PlaybackController` that calls `pause()`, and show a countdown in the player.
- [ ] **Mark played/unplayed and remove from history.** Swipe actions on broadcast-log cards. History and saved positions are keyed by `streamUrl`.
- [ ] **Episode details sheet.** Long-press shows the full show notes (`description` with HTML stripped) and a Play button.
- [ ] **Exact ON AIR matching.** Store the podcast's `rssFeedUrl` on each `Episode` (GRDB migration), so the badge stops matching by author name.

## Bigger features

- [ ] **Downloads for offline listening.** `Episode.fileUrl` exists but is unused. Needs background `URLSession` downloads, a download indicator on schedule rows, and playback from the local file when it exists.
- [ ] **New-episode tracking for presets.** Check favorite feeds for new episodes, show a "NEW" badge on station tiles, and add a "Fresh on Air" shelf on the Podcasts screen. Later: `BGAppRefreshTask` and notifications.
- [ ] **Up Next queue editing.** Reorder, "Play next" / "Play later", and remove. `PlaybackController` already has a queue, but it's only filled from a single list.
- [ ] **Browse by category.** Use the iTunes Search API's `genreId` to show bands of stations (News, Comedy, Tech…) instead of only searching for `"podcasts"`.
- [ ] **Chapters.** Read them from the feed or the audio file's metadata.
- [ ] **Skip silence.** Needs audio processing.

## Platform integration

- [ ] **Home Screen widget.** "Now On Air" / "Continue listening" with a play button (App Intents).
- [ ] **Live Activity.** Lock Screen and Dynamic Island showing the on-air episode.
- [ ] **Siri and Shortcuts.** "Tune in to [preset]" and "Resume my podcast" via App Intents.
- [ ] **CarPlay.** Audio app with presets and the broadcast log as list templates.
- [ ] **iCloud sync.** Favorites, history and resume positions across iPhone and iPad. Positions are in `UserDefaults` today; move them to `NSUbiquitousKeyValueStore` or CloudKit.

## Quality

- [ ] **Tests for new logic.** History re-insert ordering in `EpisodesRepository.saveInHistory`, and the Up Next calculation in the player.
- [ ] **Remove dead code.** `StandardListItemView`, `StandardListLoadingView` (and `listRowCard()`), `PodcastThumbnailCell`, `HistoryItemCell`.
- [ ] **Remove stale schemes.** `Podcasts AppTests` and `PodcastsUITests` reference targets that no longer exist.
