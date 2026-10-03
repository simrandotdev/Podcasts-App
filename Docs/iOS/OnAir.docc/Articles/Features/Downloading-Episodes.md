# Downloading Episodes

Save episodes for offline listening, with downloads that continue in the background.

## Overview

`DownloadManager.shared` downloads episodes with a background `URLSession`, so downloads continue while the app is suspended or not running. `DownloadStore` keeps the files on disk. Views reach both through `DownloadsViewModel`, and the Downloads tab, `DownloadsScreen`, lists everything that's downloaded or downloading.

### Follow a Download Through Its States

Every episode is in one of four `DownloadState` values. `DownloadManager.state(for:)` reports the state from the downloads in progress and the files on disk.

![A state diagram. Not downloaded moves to Downloading with download. Downloading moves to Downloaded when finished, back to Not downloaded with cancel, or to Failed on an error. Failed moves back to Downloading with retry. Downloaded moves back to Not downloaded with remove. Notes explain that the background session keeps downloading while the app is suspended, and that Download on Wi-Fi Only holds downloads until Wi-Fi is available.](download-lifecycle)

`DownloadButton` shows the state on rows and cards: a download arrow, a progress ring that cancels the download when tapped, a filled icon once it's downloaded, and a retry symbol after a failure. Rows that VoiceOver reads as one element offer the same actions as accessibility actions instead.

### Start a Download

`DownloadManager.download(_:)` does the following:

1. Ignores the request if the episode is already downloading or downloaded, and fails it if the URL isn't HTTP or HTTPS.
2. Writes the episode's details to a sidecar file right away, so a download that finishes while the app isn't running can still be listed.
3. Creates a download task with `allowsCellularAccess` set to the opposite of the Download on Wi-Fi Only setting.
4. Sets the task's `taskDescription` to the episode's `streamUrl`. The description survives relaunches, so a finished download can always be matched to its episode.

### Store the Files

`DownloadStore` keeps downloads in `Application Support/Downloads`. It names each file with the SHA-256 hash of the episode's `streamUrl`, so the file can always be found from the URL alone. It never stores absolute paths, because the app container's path can change.

![The streamUrl goes through SHA-256 to produce a 64-character stem. The Application Support/Downloads folder, excluded from iCloud backup, holds the stem with an audio extension and the stem with a json extension, which contains the Episode.](download-files)

- The audio file keeps a real audio extension, taken from the URL or the response's MIME type, because `AVPlayer` chooses a decoder from the extension. It falls back to `mp3`.
- The `.json` sidecar holds the `Episode`, which is what the Downloads tab lists from.
- The folder is excluded from iCloud backups, because episodes can be downloaded again.

### Keep Downloading in the Background

The session's configuration sets `sessionSendsLaunchEvents`, so iOS relaunches the app to deliver finished downloads. It also turns off `isDiscretionary`, because the user asked for the episode now.

When iOS relaunches the app for download events, `AppDelegate` stores the completion handler and creates `DownloadManager.shared`, which reconnects to the session. The manager calls the handler once the session reports that every event has been delivered. On launch, the manager also asks the session for its running tasks, so downloads that kept going while the app was gone show their progress again.

### Play Downloaded Episodes

`PlaybackManager` receives a `localFile` closure that asks `DownloadStore` for an episode's file. When the file exists, the episode plays from disk, with or without a connection.

### Download on Wi-Fi Only

The Download on Wi-Fi Only setting in Settings is stored under `downloadsWiFiOnly`. It applies to downloads started after it changes. An `NWPathMonitor` tracks whether a Wi-Fi or wired connection is available. When the setting is on and there's no Wi-Fi, the background session holds new downloads until Wi-Fi returns, and the Downloads tab marks the ones that haven't started "Waiting for Wi-Fi".

### Manage Downloads

The Downloads tab has up to three sections:

- term Downloading: Downloads in progress, with their progress and a Cancel button, and failed downloads, with the error and a Retry button.
- term On Your Device: Finished downloads, newest first, with their file sizes. A tap plays the episode with the other downloads as the queue, and swiping deletes a download. A Remove All button deletes them all, after a confirmation that shows how much space it frees.
- term Earlier Downloads: Files saved before the app recorded episode details. When the app sees the episode again in the history or on a podcast's page, `identifyDownloads(from:)` writes its sidecar and the file moves to On Your Device. The Remove Earlier Downloads button deletes the rest.

The Delete All Downloaded Episodes button in Settings removes every finished download. Downloads in progress keep going.

## See Also

- <doc:Playing-Episodes>
- <doc:Configuring-Settings>
- <doc:Storing-Data>
