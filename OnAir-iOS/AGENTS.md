# Repository Guidelines

## Project Structure & Module Organization

This is a Swift 5 iOS podcast app combining SwiftUI screens with UIKit playback components. The app targets iOS 15.0; unit tests target iOS 15.4.

- `Podcasts App/Source/Presentation Layer/`: screens, reusable cells, tab navigation, and the player view/XIB.
- `Podcasts App/Source/Business Layer/`: models, view models, controllers, and interactors.
- `Podcasts App/Source/Data Layers/`: API networking, repositories, and persistence. Preserve the existing `Persistance` directory spelling.
- `Podcasts App/Source/Utility/`: extensions, constants, and logging.
- `Podcasts App/Support/`: app delegate, asset catalog, and launch storyboard.
- `Podcasts App Unit Tests/`: XCTest cases and mock interactors.

Keep UI behavior in presentation components, orchestration in controllers/interactors, and data access in repositories.

## Build, Test, and Development Commands

Run commands from `OnAir-iOS/`. Xcode fetches the Swift packages on the first build.

```sh
open "Podcasts App.xcworkspace"
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -showdestinations
xcodebuild -workspace "Podcasts App.xcworkspace" -scheme "Podcasts App" -destination 'platform=iOS Simulator,id=<SIMULATOR_UUID>' test
```

These commands open the workspace, build, list destinations, and run tests. Replace the simulator placeholder with an available ID. To run locally, select the app scheme and a simulator in Xcode, then press Command-R. Use the workspace, because the package versions are pinned in its `Package.resolved`.

## Coding Style & Naming Conventions

Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` methods/properties. Match filenames to their main type. Follow existing suffixes such as `Screen`, `Controller`, `Interactor`, `Repository`, and `ViewModel`, and use `// MARK: -` sections where helpful. Preserve Resolver dependency injection and Combine/async-await patterns. Keep UI-observable mutations on the main actor. No SwiftLint or SwiftFormat configuration is checked in; follow surrounding code.

## Testing Guidelines

Use XCTest with injected mock interactors, following `PodcastsControllerTests.swift`. Name tests `test_<behavior>_<expectedResult>`. Cover changed controller behavior and failure paths without live network dependencies. No coverage threshold is configured. Use the main app scheme.

## Commit & Pull Request Guidelines

History uses short descriptive messages without a mandatory prefix, such as “correct the favourites selection.” Keep commits focused and describe the resulting change. PRs should explain the purpose, list validation performed, link relevant issues, and include screenshots for UI changes, including iPad when affected. Commit the workspace's `Package.resolved` when dependencies change.
