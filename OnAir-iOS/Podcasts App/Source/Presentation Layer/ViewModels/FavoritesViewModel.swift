import Foundation
import Observation
import Resolver

/// Backs `FavoritesScreen`: the user's favorites, numbered as presets in the order they were saved.
/// Reloads whenever a podcast is favorited or unfavorited anywhere in the app.
@MainActor
@Observable
final class FavoritesViewModel {
    private(set) var favorites: [PodcastViewModel] = []
    /// False until the first load finishes, so the empty state doesn't flash on launch.
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let podcastsManager: PodcastsManaging
    @ObservationIgnored private var changesTask: Task<Void, Never>?

    init(podcastsManager: PodcastsManaging = Resolver.resolve()) {
        self.podcastsManager = podcastsManager
        // Subscribe now, so no change is missed, then reload after each one.
        let changes = podcastsManager.favoritesChanges()
        changesTask = Task { [weak self] in
            for await _ in changes {
                await self?.fetchFavorites()
            }
        }
    }

    deinit {
        changesTask?.cancel()
    }

    var isEmpty: Bool { hasLoaded && favorites.isEmpty && errorMessage == nil }

    func fetchFavorites() async {
        do {
            favorites = try await podcastsManager.fetchFavorites().map(PodcastViewModel.init(podcast:))
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load favorites. \(error.localizedDescription)"
        }
        hasLoaded = true
    }
}
