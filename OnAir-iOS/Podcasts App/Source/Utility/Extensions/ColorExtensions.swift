import SwiftUI

extension Color {
    /// The app's orange, from the `AccentColor` asset.
    ///
    /// Use it instead of `Color.accentColor`. iOS 18 doesn't reliably apply the asset catalog's accent color, and
    /// `Color.accentColor` then falls back to the system blue. `PodcastsApp` also sets it as the root `.tint`, which
    /// system controls such as buttons and the tab bar follow.
    static let onAir = Color("AccentColor")
}
