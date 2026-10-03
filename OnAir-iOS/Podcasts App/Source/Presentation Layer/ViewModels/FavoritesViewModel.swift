import Foundation
import Resolver
import Combine

/// Backs `FavoritesScreen`: the user's favorites, numbered as presets in the order they were saved.
/// Reloads whenever a podcast is favorited or unfavorited anywhere in the app.
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favorites: [PodcastViewModel] = []
    /// False until the first load finishes, so the empty state doesn't flash on launch.
    @Published private(set) var hasLoaded = false
    @Published private(set) var errorMessage: String?

    private let podcastsManager: PodcastsManaging
    private var subscription: AnyCancellable?

    init(podcastsManager: PodcastsManaging = Resolver.resolve()) {
        self.podcastsManager = podcastsManager
        subscription = podcastsManager.favoritesDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { await self?.fetchFavorites() }
            }
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
