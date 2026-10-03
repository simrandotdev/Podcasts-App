# Tracking New Episodes

Find new episodes of the user's presets, show them on the Fresh on Air shelf, and send notifications.

## Overview

`NewEpisodesManager.shared` checks the feed of every preset for episodes the user hasn't seen. Views reach it through `NewEpisodesViewModel`. Its results appear in three places:

- term Fresh on Air: A shelf at the top of the Home tab with every new episode, newest first.
- term NEW badges: A count on each station tile, on the Home and Favorites tabs.
- term Notifications: One alert per podcast with something new, when the user turns on New Episode Alerts.

### Decide What's New

An episode counts as new only if both of these are true:

- Its `streamUrl` wasn't in the feed when the user last opened that podcast.
- Its publication date is later than that visit.

Requiring both keeps undated episodes from appearing as new on every check. FeedKit dates an episode without a `pubDate` as the moment the feed was parsed.

![A flowchart. Checks run on launch and return to the foreground, on pull to refresh, from Check Now in Settings, and during background app refresh. Each check loads the presets and fetches every feed at once. On the first check of a preset, every current episode counts as old. Otherwise the check keeps episodes that weren't in the feed at the last visit, weren't played from the shelf, and are dated after the last visit. It keeps the newest 10 per podcast, saves NewEpisodes.json, and notifies once per episode. Opening a podcast or playing an episode from the shelf clears new episodes.](new-episode-detection)

A check works like this:

1. It loads the presets with `PodcastsManaging.fetchFavorites()`.
2. It fetches every preset's feed at the same time, in a task group. A feed that fails keeps the results from the previous check.
3. The first time it sees a preset, it records every episode in the feed as already known, so the user doesn't get a flood of "new" episodes from a podcast they just saved.
4. For other presets, it keeps the new episodes, skips any the user has played from the shelf, and keeps the newest 10 per podcast.
5. It forgets presets that the user has removed, then saves the state and publishes the result.

### Clear New Episodes

- term Opening a podcast: `PodcastDetailViewModel` calls `markSeen(_:episodeUrls:)` after loading the episodes. That sets the visit date to now, adds every current episode to the known list, and clears the podcast's NEW badge and its shelf episodes.
- term Playing from the shelf: `FreshOnAirRow` calls `markPlayed(_:)`, which removes the episode from the shelf and remembers it, so the next check doesn't bring it back.

### Schedule Checks

| When | Method | Notes |
| --- | --- | --- |
| The app becomes active | `refreshIfStale()` | Skipped if a check ran in the last 15 minutes |
| Pull to refresh on Home or Favorites | `refresh()` | Always checks |
| Check Now in Settings | `refresh()` | Shows when the last check ran |
| Background app refresh | `refreshInBackground()` | iOS chooses the time |

When the app moves to the background, `scheduleBackgroundRefresh()` submits a `BGAppRefreshTaskRequest` with an earliest start one hour away. `PodcastsApp` handles the task with SwiftUI's `.backgroundTask(.appRefresh(_:))` modifier. The handler schedules the next refresh first, which keeps the chain going, and then runs a check. The task identifier is listed in `BGTaskSchedulerPermittedIdentifiers` in `Info.plist`.

### Send Notifications

Turning on New Episode Alerts asks for notification permission. If the user denies it, the setting stays off, and Settings explains how to allow notifications for the app.

`UserNotificationsNotifier` sends one notification per podcast, titled "New on" and the podcast's name. The body is the episode title, or a count when there are several. Each notification's thread identifier is the podcast's feed URL, so Notification Center groups them by podcast.

Each episode is announced once. The manager records announced episodes even while alerts are off, so turning alerts on later doesn't announce a backlog.

### Persist the State

The state is saved to `Application Support/NewEpisodes.json` after every change, and loaded at launch, so badges and the shelf appear before the first check finishes. It holds the date of each podcast's last visit, the episodes known for each feed, the current new episodes, the episodes played from the shelf, the episodes already announced, and the time of the last check. The lists of played and announced episodes keep only their 500 most recent entries.

## See Also

- <doc:Saving-Presets>
- <doc:Discovering-Podcasts>
- <doc:Configuring-Settings>
