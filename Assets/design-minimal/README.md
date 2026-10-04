# On Air — Minimal screenshot set

Seven PNG screenshots at 1242 × 2688 pixels, saved in `../AppStore-Minimal-1242x2688/`. Upload in filename order. `../Preview-Minimal.png` shows the entire set, and `../OnAir-AppStore-Minimal-1242x2688.zip` contains the seven screenshots.

The minimal direction uses a flat warm off-white background, centered black typography, a small app icon and name, and iPhone 16 Pro frames in Natural Titanium. The device frames include the metal surround, camera cutout, and side buttons. The original app interface provides the color. There are no decorative background effects, equalizers, feature badges, or page numbers.

The six original app screens and the supplied app icon are reused directly. Full screenshots are scaled into the iPhone display area, with corner clipping; UI content is not regenerated. All device frames retain full iPhone proportions, including the player. The final screenshot shows separate home and player iPhones.

Frame asset: [iPhone 16 Pro — Natural Titanium, Maya](https://github.com/ronaldo-avalos/Maya/tree/main/Maya/Assets.xcassets/iphone%20frames). This is a third-party device frame asset, not an Apple marketing download. Copyright 2026 Ronaldo Avalos, MIT license; see `assets/LICENSE-Maya.txt`. The 450 × 920 frame has a 402 × 874 display at (24,23), matching the supplied 1206 × 2622 screenshots at 3×. The source bezel PNG is saved in `assets/iphone-16-pro-natural-titanium.png`.

`render.swift` is the editable source. Run it with Swift from the parent folder on macOS. It recreates the seven PNGs and contact sheet. `validation.json` records the dimensions and RGB format checks. Files use 8-bit RGB without an alpha channel.

The first screenshot set remains unchanged.
