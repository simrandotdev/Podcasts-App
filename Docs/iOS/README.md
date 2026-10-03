# On Air for iOS: Documentation

This folder holds the developer documentation for the iOS app in `OnAir-iOS/`, written as a DocC catalog. It explains the app's architecture and each of its features, with block diagrams.

| Path | Contents |
| --- | --- |
| `OnAir.docc/OnAir.md` | The landing page and the table of contents |
| `OnAir.docc/Articles/Essentials/` | Architecture, request walkthroughs, and building the app |
| `OnAir.docc/Articles/Features/` | One article per feature |
| `OnAir.docc/Articles/Infrastructure/` | Navigation, storage, networking, dependency injection, and testing |
| `OnAir.docc/Resources/` | Diagrams (light and `~dark` SVGs), screenshots, and the app icon |
| `Diagrams/generate_diagrams.py` | Draws every diagram in `Resources/` |

## Read the Documentation

Run this from the repository root, then open <http://localhost:8080/documentation/onair>:

```sh
xcrun docc preview Docs/iOS/OnAir.docc
```

The preview rebuilds when an article changes.

## Build a Static Site

To build a copy for a web server or GitHub Pages:

```sh
xcrun docc convert Docs/iOS/OnAir.docc \
    --output-path Docs/iOS/.build/OnAir.doccarchive \
    --transform-for-static-hosting
```

For hosting below the domain root, such as `https://<user>.github.io/<repo>/`, add `--hosting-base-path <repo>`. Git ignores `.build` folders, so build output stays out of the repository. Double-clicking a `.doccarchive` also opens it in Xcode's documentation window.

## Update the Diagrams

The diagrams are generated, so edit `Diagrams/generate_diagrams.py` rather than the SVG files, then run:

```sh
python3 Docs/iOS/Diagrams/generate_diagrams.py
```

The script needs only Python 3. It writes a light and a dark version of each diagram, and warns when a label is probably too long for its box.

## Keep the Documentation Current

When a change to the app affects behavior that an article describes, update the article in the same pull request. The screenshots came from a device running the app and are stored at 600 pixels wide.
