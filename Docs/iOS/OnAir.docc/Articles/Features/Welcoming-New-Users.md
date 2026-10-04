# Welcoming New Users

Introduce On Air with a short tour the first time someone opens the app.

## Overview

The first time the app launches after it's installed, a welcome tour follows the splash animation. Its five pages explain what On Air does. The last page offers to turn on New Episode Alerts. The tour is `OnboardingView`, backed by `OnboardingViewModel`, and the Home tab loads underneath it, so trending stations are ready when the user finishes.

@Row {
    @Column(size: 2) {
        | Page | Title | What it covers |
        | --- | --- | --- |
        | 1 | Welcome to On Air | Podcasts that work like a radio |
        | 2 | Find Your Stations | Trending podcasts and search |
        | 3 | Save Presets | Favorites as numbered presets |
        | 4 | Listen Anywhere | Downloads, resume positions, and playback speed |
        | 5 | Never Miss an Episode | Fresh on Air, and an optional Turn On Alerts button |

        Continue moves to the next page, and the user can also swipe between pages. Skip, on every page but the last, closes the tour, as does Start Listening on the last page.
    }
    @Column {
        ![The first page of the welcome tour: the On Air icon inside radio-wave rings, the title Welcome to On Air, a short description, page dots, and a Continue button.](screen-onboarding)
    }
}

### Decide When the Tour Shows

`OnboardingViewModel` reads `hasCompletedOnboarding` from `UserDefaults`. While it's false, `isPresented` is true, and `PodcastsApp` presents the tour as a full-screen cover once the splash finishes.

- Finishing or skipping the tour calls `finish()`, which sets `hasCompletedOnboarding`, so the tour doesn't show again.
- The Welcome Tour button in Settings calls `showAgain()` to replay it. See <doc:Configuring-Settings>.

> Note: Anyone who updates from a version without the tour also sees it once, because they don't have `hasCompletedOnboarding` yet either.

### Turn On Alerts from the Tour

The Turn On Alerts button calls `OnboardingViewModel.turnOnAlerts()`, which asks `NewEpisodesManager` to turn on New Episode Alerts. That asks iOS for permission to send notifications. If the user allows it, the button changes to "New Episode Alerts are on". If not, the tour says alerts can be turned on later in Settings. The tour never asks for permission until the user taps the button. See <doc:Tracking-New-Episodes>.

### Design the Pages

The tour always uses the dark appearance, with the midnight navy and orange of the app icon. Each page shows its artwork inside radio-wave rings: the app icon on the first page, and an SF Symbol in the app's orange on the others. The symbol bounces when its page appears, unless Reduce Motion is on.

The pages adapt to their space:

- Each page scrolls when its content is taller than the screen, as at the largest text sizes. Shorter pages stay centered.
- The artwork shrinks at accessibility text sizes, and on short screens such as iPhone SE.
- On iPad, the content is at most 560 points wide, so lines stay easy to read.

Like the rest of the app, the tour colors its artwork with `Color.onAir`, the `AccentColor` asset, and sets it as the tint for its buttons. See <doc:Navigating-the-App>.

## See Also

- <doc:Navigating-the-App>
- <doc:Tracking-New-Episodes>
- <doc:Configuring-Settings>
