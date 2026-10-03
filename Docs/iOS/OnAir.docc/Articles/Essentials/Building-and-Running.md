# Building and Running On Air

Open the workspace, build the app, and run its tests.

## Overview

The iOS app lives in the `OnAir-iOS` folder. It targets iOS 16.0 and runs on iPhone and iPad. Its two dependencies come from Swift Package Manager, pinned in the workspace's `Package.resolved`:

| Package | Requirement | Used for |
| --- | --- | --- |
| FeedKit | 9.x, from 9.1.2 | Parsing RSS feeds |
| Resolver | 1.x, from 1.5.0 | Dependency injection |

### Open the Project

Open `OnAir-iOS/Podcasts App.xcworkspace`, not the project inside it, because the package versions are pinned in the workspace. Xcode fetches the packages on the first build. Choose the Podcasts App scheme, which is the only scheme, and an iPhone or iPad simulator.

### Run the On Air API

Debug builds find podcasts through the On Air API at `http://127.0.0.1:8000`. Start it before running the app, from the repository's `OnAirAPI` folder:

```sh
uv run uvicorn app.main:app --reload
```

The service needs a Podcast Index API key and secret in `OnAirAPI/.env`. `OnAirAPI/README.md` explains the setup. Without the service, the Home tab shows an error with a Retry button. Release builds leave `ONAIR_API_BASE_URL` empty and use the iTunes Search API until the service is deployed. See <doc:Loading-Podcasts-and-Feeds>.

### Build and Test from the Command Line

Run these commands from the `OnAir-iOS` folder:

```sh
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" \
    -destination 'generic/platform=iOS Simulator' build

xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

To run a single test class or method, add `-only-testing`:

```sh
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test \
    -only-testing:"Podcasts App Unit Tests/PlaybackManagerTests/test_close_savesProgressAndClearsPlayback"
```

The project has no lint or formatting tools.

### Know the Targets

| Target | Product | Notes |
| --- | --- | --- |
| Podcasts App | `Podcasts Bin.app`, displayed as On Air | Bundle identifier `ca.bytesizedsoftware.on-air` |
| Podcasts App Unit Tests | A unit test bundle hosted by the app | XCTest; see <doc:Testing-the-App> |

### Review the App's Configuration

Several features depend on entries in `Info.plist`:

| Key | Value | Purpose |
| --- | --- | --- |
| `UIBackgroundModes` | `audio`, `fetch` | Keeps audio playing in the background, and lets iOS wake the app to check for new episodes |
| `BGTaskSchedulerPermittedIdentifiers` | `ca.bytesizedsoftware.hello-podcasts.refresh` | Permits the new-episode background refresh task |
| `NSAppTransportSecurity` | `NSAllowsArbitraryLoads` set to `true` | Allows feeds and audio served over plain HTTP, which many podcasts still use |
| `UILaunchScreen` | The `SplashIcon` image | Draws the launch screen that `SplashView` continues |

Downloads use a background `URLSession` with the identifier `ca.bytesizedsoftware.hello-podcasts.downloads`, defined as `DownloadManager.sessionIdentifier`.

> Important: If you rename the refresh task, update `BGTaskSchedulerPermittedIdentifiers` to match. If you rename the download session, the app loses track of downloads that are already running.

### Preview This Documentation

From the repository root, run:

```sh
xcrun docc preview Docs/iOS/OnAir.docc
```

Then open `http://localhost:8080/documentation/onair` in a browser. `Docs/iOS/README.md` explains how to build a static copy and how to redraw the diagrams.

## See Also

- <doc:Architecture>
- <doc:Testing-the-App>
