import SwiftUI

struct AppTabView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Shared by several screens: Home and Favorites both show presets; Home, Recently Played and
    // Downloads all use the listening history.
    @State private var home = HomeViewModel()
    @State private var favorites = FavoritesViewModel()
    @State private var history = HistoryViewModel()
    @State private var isPlayerExpanded = false
    @State private var selection: AppSection? = .home

    private enum AppSection: String, CaseIterable, Identifiable {
        case home = "Home", favorites = "Favorites", history = "Recently Played", downloads = "Downloads",
             settings = "Settings"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .home: return "magnifyingglass"
            case .favorites: return "heart.fill"
            case .history: return "music.mic"
            case .downloads: return "arrow.down.circle"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(AppSection.allCases, selection: $selection) { section in
                        NavigationLink(value: section) {
                            Label(section.rawValue, systemImage: section.symbol)
                        }
                    }
                    .navigationTitle("Menu")
                } detail: {
                    NavigationStack {
                        screen(selection ?? .home)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                }
            } else {
                TabView(selection: $selection) {
                    ForEach(AppSection.allCases) { section in
                        NavigationStack {
                            screen(section)
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                        .tabItem { Label(section.rawValue, systemImage: section.symbol) }
                        .tag(Optional(section))
                    }
                }
            }
        }
        .environment(home)
        .environment(favorites)
        .environment(history)
        .overlay(alignment: .trailing) {
            if isPlayerExpanded, player.episode != nil {
                PlayerDetailsView { isPlayerExpanded = false }
                    .frame(maxWidth: horizontalSizeClass == .regular ? 440 : .infinity)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    .shadow(radius: horizontalSizeClass == .regular ? 12 : 0)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.9),
                   value: isPlayerExpanded)
        .onChange(of: player.episode == nil) { _, isEmpty in
            if isEmpty { isPlayerExpanded = false }
        }
        .alert("Playback", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { player.errorMessage = nil }
        } message: {
            Text(player.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var miniPlayer: some View {
        if player.episode != nil {
            MiniPlayerView { isPlayerExpanded = true }
        }
    }

    @ViewBuilder
    private func screen(_ section: AppSection) -> some View {
        switch section {
        case .home: PodcastsScreen(maximizePlayerView: play)
        case .favorites: FavoritesScreen(maximizePlayerView: play)
        case .history: RecentlyPlayedEpisodesScreen(maximizePlayerView: play)
        case .downloads: DownloadsScreen(maximizePlayerView: play)
        case .settings: SettingsView()
        }
    }

    /// Plays (or resumes) an episode and expands the player. With no episode, just expands it.
    private func play(_ episode: EpisodeViewModel?, _ queue: [EpisodeViewModel]?) {
        if let episode { player.play(episode, queue: queue ?? [episode]) }
        if player.episode != nil { isPlayerExpanded = true }
    }
}

#Preview {
    AppTabView()
        .environment(PlayerViewModel(playback: PlaybackManager(systemPlaybackEnabled: false, saveHistory: { _ in })))
        .environment(DownloadsViewModel())
        .environment(NewEpisodesViewModel())
        .environment(OnboardingViewModel())
}
