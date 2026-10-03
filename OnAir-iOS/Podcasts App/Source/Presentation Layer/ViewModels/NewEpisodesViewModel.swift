import Foundation
import Combine

/// New episodes of the user's favorites, for the Fresh on Air shelf, NEW badges and Settings.
/// Wraps the app's `NewEpisodesManager`.
@MainActor
final class NewEpisodesViewModel: ObservableObject {
    /// A new episode on the Fresh on Air shelf.
    struct Item: Identifiable {
        let episode: EpisodeViewModel
        let podcastTitle: String
        let podcastImage: String
        var id: String { episode.streamUrl }
    }

    /// New episodes across all favorites, newest first.
    @Published private(set) var freshEpisodes: [Item] = []

    private let manager: NewEpisodesManager
    private var subscription: AnyCancellable?

    /// - Parameter manager: Defaults to the app's shared new-episodes manager.
    init(manager: NewEpisodesManager? = nil) {
        let manager = manager ?? .shared
        self.manager = manager
        manager.$freshEpisodes
            .map { $0.map { Item(episode: EpisodeViewModel(episode: $0.episode), podcastTitle: $0.podcastTitle,
                                 podcastImage: $0.podcastImage) } }
            .assign(to: &$freshEpisodes)
        subscription = manager.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - State

    var isRefreshing: Bool { manager.isRefreshing }
    var lastRefresh: Date? { manager.lastRefresh }
    var notificationsEnabled: Bool { manager.notificationsEnabled }

    /// Number of new episodes for a podcast, for its NEW badge.
    func newCount(for podcast: PodcastViewModel) -> Int {
        manager.newCount(for: podcast.rssFeedUrl)
    }

    // MARK: - Actions

    /// Checks every favorite's feed now.
    func refresh() async { await manager.refresh() }

    /// Checks unless a check ran recently; for app launch and returning to the foreground.
    func refreshIfStale() async { await manager.refreshIfStale() }

    /// Asks iOS to wake the app later to check for new episodes.
    func scheduleBackgroundRefresh() { manager.scheduleBackgroundRefresh() }

    /// Takes an episode off the shelf when it's played from there.
    func markPlayed(_ episode: EpisodeViewModel) { manager.markPlayed(episode.streamUrl) }

    /// Turns alerts on or off, asking for permission when turning them on. Returns whether they're on.
    func setNotificationsEnabled(_ isOn: Bool) async -> Bool {
        await manager.setNotificationsEnabled(isOn)
    }
}
