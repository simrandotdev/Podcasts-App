# Navigating the App

Present the same five sections as tabs on iPhone and as a sidebar on iPad, with the player always in reach.

## Overview

`AppTabView` is the root view. It defines the app's sections, chooses a layout from the horizontal size class, and hosts the mini player and the expanded player for every screen.

![On iPhone, a NavigationStack holds the selected screen, with the mini player in the bottom safe-area inset above a TabView. On iPad, a NavigationSplitView sidebar lists the sections, and the detail column holds a NavigationStack, the selected screen, and the mini player. The expanded player covers the iPhone screen and slides over the trailing edge on iPad, at most 440 points wide.](app-shell)

| Section | Screen | Symbol |
| --- | --- | --- |
| Home | `PodcastsScreen` | `magnifyingglass` |
| Favorites | `FavoritesScreen` | `heart.fill` |
| Recently Played | `RecentlyPlayedEpisodesScreen` | `music.mic` |
| Downloads | `DownloadsScreen` | `arrow.down.circle` |
| Settings | `SettingsView` | `gearshape` |

### Use Tabs in Compact Width

In compact width, `AppTabView` shows a `TabView` with one tab per section. Each tab has its own `NavigationStack`, so each keeps its own navigation path when the user switches tabs. The mini player sits in each tab's bottom safe-area inset, above the tab bar.

### Use a Sidebar in Regular Width

In regular width, it shows a `NavigationSplitView`. The sidebar, titled Menu, lists the sections, and the detail column shows the selected section in a `NavigationStack`, with the mini player at its bottom.

> Note: The layout follows the size class, not the device. An iPad app in a narrow Split View or Slide Over window is compact, so it gets tabs.

### Expand the Player

Tapping the mini player sets `isPlayerExpanded`, and `AppTabView` shows `PlayerDetailsView` as an overlay on its trailing edge. In compact width the player is full width. In regular width it's at most 440 points wide, with a shadow, so the screen beneath stays visible.

The player slides up from the bottom with a spring animation. With Reduce Motion on, it fades instead. When playback closes, the player collapses on its own. If playback fails, `AppTabView` shows the error in a Playback alert.

### Start Playback from Any Screen

Screens never hold the player. `AppTabView` passes each screen a `maximizePlayerView(episode, queue)` closure. Calling it with an episode plays that episode with the queue and expands the player. Calling it without one just expands the player. See <doc:Playing-Episodes>.

### Share View Models Between Screens

`PodcastsApp` creates the app-wide view models, `PlayerViewModel`, `DownloadsViewModel`, and `NewEpisodesViewModel`, and places them in the environment. `AppTabView` adds the view models that several screens share: `HomeViewModel`, `FavoritesViewModel`, and `HistoryViewModel`. Sheets, such as `EpisodeDetailsSheet`, receive the environment objects they need explicitly.

### Show the Launch Animation

iOS shows a static launch screen, defined by `UILaunchScreen` in `Info.plist`, with the `SplashIcon` image on the system background. `PodcastsApp` then lays `SplashView` over the app, with the same image at the same size, so the handoff is seamless. After a short pause, the icon dips slightly, then zooms past the edges of the screen while the background fades to reveal the app. With Reduce Motion on, the splash simply fades out.

### Apply the Station Style

- `PodcastsApp` sets the rounded system font for the whole app.
- Screen titles carry an emoji, such as "On Air 📻" and "Favorites ❤️".
- `OnAirBadge` and `NewBadge` mark playing podcasts and new episodes wherever podcasts appear.
- Layouts use `ViewThatFits` to stack controls vertically at large text sizes instead of truncating them, and level meters stand still when Reduce Motion is on.

## See Also

- <doc:Architecture>
- <doc:Playing-Episodes>
- <doc:Discovering-Podcasts>
