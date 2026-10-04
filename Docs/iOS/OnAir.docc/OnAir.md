# On Air

A radio-inspired podcast player for iPhone and iPad, built with SwiftUI.

@Metadata {
    @TechnologyRoot
    @PageImage(purpose: icon, source: "app-icon", alt: "The On Air app icon.")
    @PageColor(orange)
}

## Overview

On Air presents podcasts as radio stations. Shows appear as station tiles, favorites become numbered presets, the listening history reads like a broadcast log, and an ON AIR badge marks whatever is playing. Behind that styling is a complete podcast player: it searches Podcast Index through its own API, streams or downloads episodes, remembers each episode's position, and checks the user's presets for new episodes.

@Row {
    @Column {
        ![The Home tab, with the Recently Played shelf above a grid of station tiles.](screen-home)
    }
    @Column {
        ![The expanded player, with an episode on air and its playback controls.](screen-player)
    }
    @Column {
        ![The episode details sheet over the broadcast log, with show notes and a Resume button.](screen-episode-details)
    }
}

The app uses SwiftUI with the Model-View-ViewModel (MVVM) pattern and repositories. Views read view models, view models call managers, managers call repositories, and repositories reach the network and the database. Start with <doc:Architecture> to learn the layers and the rules between them. Then read the feature articles to see how each part of the app works.

| Area | Technology |
| --- | --- |
| Interface | SwiftUI on iOS 18 and later, for iPhone and iPad |
| State and concurrency | Observation (`@Observable`) and Swift concurrency, with no Combine or GCD |
| Playback | AVFoundation and MediaPlayer |
| Persistence | Core Data, files in Application Support, and `UserDefaults` |
| Networking | `URLSession`, the On Air API backed by Podcast Index, and FeedKit for RSS |
| Dependency injection | Resolver |
| Background work | A background `URLSession` and BackgroundTasks |

## Topics

### Essentials

- <doc:Architecture>
- <doc:Following-a-Request>
- <doc:Building-and-Running>

### Features

- <doc:Welcoming-New-Users>
- <doc:Discovering-Podcasts>
- <doc:Viewing-a-Podcast>
- <doc:Saving-Presets>
- <doc:Playing-Episodes>
- <doc:Downloading-Episodes>
- <doc:Tracking-New-Episodes>
- <doc:Keeping-a-Listening-History>
- <doc:Measuring-Listening-Activity>
- <doc:Configuring-Settings>

### App Infrastructure

- <doc:Navigating-the-App>
- <doc:Storing-Data>
- <doc:Loading-Podcasts-and-Feeds>
- <doc:Injecting-Dependencies>
- <doc:Testing-the-App>
