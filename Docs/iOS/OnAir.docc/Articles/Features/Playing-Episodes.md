# Playing Episodes

Listen with a player that survives navigation, remembers each episode's position, and works from the Lock Screen.

## Overview

One object plays every episode: `PlaybackManager.shared`. It owns a single `AVPlayer` for the life of the app, so playback continues while the user moves between screens. Views reach it through `PlayerViewModel`, which `PodcastsApp` places in the environment.

![PlaybackManager in the center. Above it, PlayerViewModel reads its published state. On the left, MPRemoteCommandCenter and AVAudioSession send it commands and interruptions. On the right, it drives AVPlayer and MPNowPlayingSession. Below it, it reads and writes UserDefaults, asks DownloadStore for downloaded files, and records plays through EpisodesManaging.](playback-system)

### Start Playback

Every screen starts playback the same way: it calls `maximizePlayerView(episode, queue)`, which `AppTabView` forwards to `PlayerViewModel.play(_:queue:)` before expanding the player. The queue is the list the episode came from:

| Started from | Queue |
| --- | --- |
| A podcast's schedule, or Tune In | Every episode in the podcast's feed |
| Recently Played | The whole listening history |
| Downloads | Every downloaded episode |
| The Fresh on Air shelf | Every episode on the shelf |

If the episode is already loaded, `PlayerViewModel` resumes it rather than reloading it. Otherwise `PlaybackManager.load(_:queue:autoplay:)` replaces the player's item. If the queue doesn't contain the episode, the manager puts the episode at the front. For the step-by-step path, see <doc:Following-a-Request>.

Before loading, the manager looks for a downloaded copy of the episode and plays it when there is one. See <doc:Downloading-Episodes>.

### Resume Where the User Left Off

`PlaybackManager` saves the position of the current episode in `UserDefaults`, keyed by its `streamUrl`. It saves every second while the episode plays, and also on pause, on seek, before loading another episode, and when the app leaves the foreground. When an episode loads, the player seeks to its saved position as soon as the item is ready.

The manager also stores each episode's length under `duration:<streamUrl>`. With both values, `progress(for:)` can compute how much of any episode has been played, which is what the progress bars throughout the app show.

When an episode ends, playback pauses and the position stays at the end, so the episode reads as finished. The player doesn't move to the next episode by itself. Playing a finished episode again starts it from the beginning.

### Use the Player

@Row {
    @Column(size: 2) {
        `PlayerDetailsView` is the expanded player. From top to bottom, it shows:

        - The artwork, with an ON AIR ring while it plays.
        - A dark "radio display" with the episode title, the show, and a level meter that moves while audio plays.
        - A scrubber over a tuner-style scale, with the elapsed, total, and remaining time.
        - Previous, back 15 seconds, play or pause, forward 15 seconds, and next.
        - Speed buttons for 1×, 1.25×, 1.5×, and 2×.
        - An Up Next card for the following episode in the queue. Tapping it plays that episode.

        Dragging the player down, or tapping the chevron, minimizes it. The close button stops playback and clears the player.
    }
    @Column {
        ![The expanded player, showing the artwork with an ON AIR badge, the radio display, the scrubber, and the playback controls.](screen-player)
    }
}

The chosen speed is saved under `playbackRate` and applies to later episodes too. The player uses the time-domain pitch algorithm, so voices keep their natural pitch at higher speeds.

### Use the Mini Player

While an episode is loaded, `MiniPlayerView` sits above the tab bar, or at the bottom of the detail column on iPad. It shows the artwork, an ON AIR line with the show name, a level meter, play or pause, forward 15 seconds, and close. A thin accent-colored line along its top edge shows how far the episode has played. Tapping the mini player or swiping up on it expands the player.

![The broadcast log with the mini player above the tab bar, showing an episode on air.](screen-mini-player)

### Control Playback from the System

`PlaybackManager` creates an `MPNowPlayingSession` for its player, which publishes the episode's title and author to the Lock Screen and Control Center. The artwork follows as soon as it downloads.

It also handles remote commands from the Lock Screen, Control Center, and headphones: play, pause, toggle, next, previous, skip forward or back 15 seconds, and scrubbing to a position. Next and previous are enabled only when the queue has an episode in that direction.

When playback starts, the manager sets the audio session's category to `.playback` with the `.spokenAudio` mode. Together with the `audio` background mode, this keeps episodes playing while the app is in the background.

### Handle Interruptions

- A phone call or another interruption pauses playback. When the interruption ends and iOS says playback should resume, it resumes, but only if it was playing before.
- Unplugging headphones, or any route change that removes the current output, pauses playback.
- If an episode has no valid audio URL, or its item fails to load, `errorMessage` is set and `AppTabView` shows it in a Playback alert.

## See Also

- <doc:Downloading-Episodes>
- <doc:Keeping-a-Listening-History>
- <doc:Measuring-Listening-Activity>
