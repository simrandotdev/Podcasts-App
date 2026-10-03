# On Air — App Store screenshot set

Seven flattened RGB PNGs at **1242 × 2688 pixels** are in `../AppStore-1242x2688/`. Upload in filename order. The ZIP contains only the seven deliverable PNGs; `../Preview.png` is a contact sheet for review.

The visual direction follows the supplied app: midnight navy and black, orange microphone branding, blue playback controls, and magenta favorites/history. Original app screenshots are embedded directly, with proportional scaling and presentation crops. The app interface, text, and artwork have not been regenerated. The final panel combines two original screens. The icon from `IMG_4187.jpg` appears in each panel.

| File | Feature | Original |
|---|---|---|
| 01-discover.png | Discovery | IMG_4181.PNG |
| 02-favorites.png | Favorites and presets | IMG_4182.PNG |
| 03-player.png | Now playing | IMG_4185.PNG |
| 04-mini-player.png | Browsing while listening | IMG_4186.PNG |
| 05-history.png | Recently played | IMG_4183.PNG |
| 06-episode-details.png | Show notes and resume | IMG_4184.PNG |
| 07-on-air.png | App overview | IMG_4181.PNG + IMG_4185.PNG |

The requested dimensions are listed by Apple for the 6.5-inch screenshot slot: [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). This set covers the requested iPhone dimensions; it does not include other device sizes.

## Editable source

`render.swift` is the final native macOS renderer. Run from the parent folder using Swift with AppKit. It recreates all seven screenshots and the preview. Headline copy, colors, positions, and source-image mappings are in this file. `assets/broadcast-background.png` is the shared background.

## Background generation

Created with the **built-in imagegen tool**, then composed with the supplied screenshots using the native renderer. No CLI image-generation fallback was used.

Prompt:

> Use case: ads-marketing. Create one premium abstract background asset for a seven-panel App Store screenshot campaign for On Air, a dark podcast listening app. Portrait aspect ratio 1242:2688. Background only: absolutely no text, no letters, no logos, no phones, no interface, no objects. Near-black midnight navy field, subtle analog audio atmosphere. Very fine flowing concentric radio signal arcs and restrained luminous orange light along lower left edge, electric blue light along lower right edge, tiny hint of magenta, dark smooth center and top 35% almost entirely clean for headline typography. Elegant technical studio lighting, subtle film grain, precise polished sparse composition, no starfield, no busy particles. Most of canvas should remain deep dark navy-black. Make background fill canvas.
