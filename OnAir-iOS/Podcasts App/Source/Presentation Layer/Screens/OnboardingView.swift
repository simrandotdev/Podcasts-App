import SwiftUI

/// One page of the welcome tour.
struct OnboardingPage: Identifiable {
    let id: Int
    /// An SF Symbol, or nil to show the app icon.
    let symbol: String?
    let title: String
    let message: String

    static let all: [OnboardingPage] = [
        OnboardingPage(id: 0, symbol: nil, title: "Welcome to On Air",
                       message: "Podcasts that work like your favorite radio. Find a show, tune in, and listen."),
        OnboardingPage(id: 1, symbol: "dot.radiowaves.left.and.right", title: "Find Your Stations",
                       message: "Browse the podcasts trending right now, or search for any show by name."),
        OnboardingPage(id: 2, symbol: "star.fill", title: "Save Presets",
                       message: "Save the shows you love as presets. Each one gets a number, like the buttons on a car radio."),
        OnboardingPage(id: 3, symbol: "arrow.down.circle.fill", title: "Listen Anywhere",
                       message: "Download episodes to play offline. Every episode picks up where you left off, at up to 2× speed."),
        OnboardingPage(id: 4, symbol: "bell.badge.fill", title: "Never Miss an Episode",
                       message: "New episodes from your presets appear in Fresh on Air. Turn on alerts to hear about them first."),
    ]
}

/// The welcome tour shown on first launch: what On Air does, in five pages, ending with an optional
/// prompt to turn on New Episode Alerts. It always uses the dark appearance, in the app icon's colors.
struct OnboardingView: View {
    let onboarding: OnboardingViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selection: Int
    @State private var alerts: AlertsState

    private let pages = OnboardingPage.all

    private enum AlertsState { case notAsked, asking, on, declined }

    /// - Parameter page: The page to start on; previews use it to show each page.
    init(onboarding: OnboardingViewModel, page: Int = 0) {
        self.onboarding = onboarding
        _selection = State(initialValue: page)
        _alerts = State(initialValue: onboarding.alertsEnabled ? .on : .notAsked)
    }

    private var isLastPage: Bool { selection == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !isLastPage {
                    Button("Skip") { onboarding.finish() }
                        .foregroundStyle(.white.opacity(0.75))
                        .accessibilityHint("Closes the welcome tour")
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 20)

            TabView(selection: $selection) {
                ForEach(pages) { page in
                    pageView(page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            footer
        }
        // Keeps lines a readable length on iPad.
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background { background }
        .tint(Color.onAir)
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .smooth, value: selection)
        .animation(reduceMotion ? nil : .smooth, value: alerts)
    }

    // MARK: - Pages

    private func pageView(_ page: OnboardingPage) -> some View {
        // A page is at least as tall as the screen, so short pages stay centered and long ones scroll.
        GeometryReader { proxy in
            ScrollView {
                pageContent(page, height: proxy.size.height)
                    .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func pageContent(_ page: OnboardingPage, height: CGFloat) -> some View {
        VStack(spacing: 28) {
            artwork(for: page, pageHeight: height)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(page.message)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            // Wrap onto as many lines as needed rather than truncating.
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
        // Room for the page dots.
        .padding(.bottom, 44)
        .frame(maxWidth: .infinity)
    }

    private func artwork(for page: OnboardingPage, pageHeight: CGFloat) -> some View {
        // Smaller at accessibility text sizes and on short screens, to leave room for the words.
        let scale: CGFloat = dynamicTypeSize.isAccessibilitySize ? 0.6 : pageHeight < 560 ? 0.7 : 1
        return ZStack {
            // Radio waves around the artwork.
            ForEach(1..<4) { ring in
                Circle()
                    .stroke(Color.onAir.opacity(0.35 / Double(ring)), lineWidth: 2)
                    .frame(width: 120 + CGFloat(ring) * 44, height: 120 + CGFloat(ring) * 44)
            }
            if let symbol = page.symbol {
                Circle()
                    .fill(Color.onAir.opacity(0.18))
                    .frame(width: 120, height: 120)
                Image(systemName: symbol)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(Color.onAir)
                    .symbolEffect(.bounce, value: !reduceMotion && selection == page.id)
            } else {
                Image("SplashIcon")
                    .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                    .shadow(color: Color.onAir.opacity(0.4), radius: 24)
            }
        }
        .frame(width: 252, height: 252)
        .scaleEffect(scale)
        .frame(width: 252 * scale, height: 252 * scale)
        .accessibilityHidden(true)
    }

    // MARK: - Buttons

    private var footer: some View {
        VStack(spacing: 12) {
            if isLastPage {
                alertsControl
            }
            Button {
                if isLastPage {
                    onboarding.finish()
                } else {
                    selection += 1
                }
            } label: {
                Text(isLastPage ? "Start Listening" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var alertsControl: some View {
        switch alerts {
        case .on:
            Label("New Episode Alerts are on", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.onAir)
                .frame(minHeight: 50)
        case .declined:
            Text("You can turn on alerts later in Settings.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(minHeight: 50)
        case .notAsked, .asking:
            Button {
                Task { await turnOnAlerts() }
            } label: {
                Label("Turn On Alerts", systemImage: "bell.badge")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(alerts == .asking)
        }
    }

    private func turnOnAlerts() async {
        alerts = .asking
        alerts = await onboarding.turnOnAlerts() ? .on : .declined
    }

    private var background: some View {
        // The midnight navy of the app icon.
        LinearGradient(colors: [Color(red: 0.04, green: 0.07, blue: 0.15), Color(red: 0.08, green: 0.14, blue: 0.28)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

#Preview("Welcome") {
    OnboardingView(onboarding: OnboardingViewModel(defaults: UserDefaults(suiteName: "OnboardingPreview")!))
}

#Preview("Alerts") {
    OnboardingView(onboarding: OnboardingViewModel(defaults: UserDefaults(suiteName: "OnboardingPreview")!), page: 4)
}
