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
        try? await Task.sleep(for: .milliseconds(250))
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { iconScale = 0.8 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeIn(duration: 0.45)) { iconScale = 25 }
            withAnimation(.easeIn(duration: 0.35).delay(0.1)) { opacity = 0 }
            try? await Task.sleep(for: .milliseconds(450))
        }
        onFinished()
    }
}

#Preview {
    SplashView {}
}
