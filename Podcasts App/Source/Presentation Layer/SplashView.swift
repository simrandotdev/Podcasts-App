import SwiftUI

/// Continues the static launch screen (`UILaunchScreen` in Info.plist) with a Twitter-style
/// reveal: the icon dips slightly, then zooms past the screen edges while the background fades
/// to uncover the app. Layout must match the launch screen so the hand-off is seamless.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var iconScale: CGFloat = 1
    @State private var opacity: Double = 1
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // No UIColorName in UILaunchScreen means the launch screen uses the system background too.
            Color(.systemBackground)
            // Same asset and natural size as the launch screen image (120 pt).
            Image("SplashIcon")
                .scaleEffect(iconScale)
        }
        .ignoresSafeArea()
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await animate() }
    }

    @MainActor
    private func animate() async {
        // Give the first screen a moment to render underneath before revealing it.
        try? await Task.sleep(nanoseconds: 250_000_000)
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(nanoseconds: 300_000_000)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { iconScale = 0.8 }
            try? await Task.sleep(nanoseconds: 250_000_000)
            withAnimation(.easeIn(duration: 0.45)) { iconScale = 25 }
            withAnimation(.easeIn(duration: 0.35).delay(0.1)) { opacity = 0 }
            try? await Task.sleep(nanoseconds: 450_000_000)
        }
        onFinished()
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView {}
    }
}
