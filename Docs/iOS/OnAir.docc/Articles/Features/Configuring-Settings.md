# Configuring Settings

Review listening activity, manage storage, and choose download and notification preferences.

## Overview

The Settings tab is `SettingsView`. It reads from three view models: its own `SettingsViewModel`, plus the shared `DownloadsViewModel` and `NewEpisodesViewModel`. Each section stores its setting where the feature that uses it can read it.

| Section | Contents | Backed by |
| --- | --- | --- |
| Listening Activity | The heatmap and the year's statistics | `SettingsViewModel` |
| Storage | Delete All Downloaded Episodes, and Clear Cache | `DownloadsViewModel` and `SettingsViewModel` |
| Downloads | Download on Wi-Fi Only | `DownloadsViewModel` |
| New Episodes | New Episode Alerts, Check Now, and the time of the last check | `NewEpisodesViewModel` |
| About | The version and build number, and the Welcome Tour button | `SettingsViewModel` and `OnboardingViewModel` |
| Debug | A subscriber toggle, in debug builds only | `DebugSettingsViewModel` |

### Manage Storage

- term Delete All Downloaded Episodes: Removes every finished download, after a confirmation that shows how much space it frees. Downloads in progress keep going.
- term Clear Cache: Empties `URLCache.shared`, which holds artwork and other responses, after a confirmation. Downloaded episodes aren't affected, and artwork downloads again as the user browses.

`PodcastsApp` sets the shared cache to 50 MB in memory and 200 MB on disk at launch. `AsyncImage` loads artwork through `URLSession.shared`, so the larger cache keeps artwork from downloading again while the user scrolls.

### Choose Download and Alert Preferences

- term Download on Wi-Fi Only: Stored under `downloadsWiFiOnly`. Applies to downloads started after it changes. See <doc:Downloading-Episodes>.
- term New Episode Alerts: Stored under `newEpisodeNotificationsEnabled`. Turning it on asks for notification permission. If iOS has notifications turned off for the app, the section says so and adds an Allow Notifications in Settings button. See <doc:Tracking-New-Episodes>.
- term Check Now: Checks every preset for new episodes immediately. While no check is running, the row shows how long ago the last one ran.

### Show the Version and the Welcome Tour

The About section shows the version, `CFBundleShortVersionString`, followed by the build number, `CFBundleVersion`, in parentheses.

The Welcome Tour button shows the tour from the first launch again. See <doc:Welcoming-New-Users>.

## See Also

- <doc:Measuring-Listening-Activity>
- <doc:Downloading-Episodes>
- <doc:Tracking-New-Episodes>
