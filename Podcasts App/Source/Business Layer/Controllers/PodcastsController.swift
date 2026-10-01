import Foundation
import Resolver
import Combine

@MainActor
final class PodcastsController: ObservableObject {
    @Injected var podcastsInteractor: PodcastsInteractable
    @Injected var episodesInteractor: EpisodesInteractable
    @Published var podcasts: [PodcastViewModel] = []
    @Published var favoritePodcasts: [PodcastViewModel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var searchSubscription: AnyCancellable?
    private var searchTask: Task<Void, Never>?
    private var requestID = UUID()

    init() { setupSearchText() }

    init(podcastsInteractor: PodcastsInteractable, episodesInteractor: EpisodesInteractable) {
        self.podcastsInteractor = podcastsInteractor
        self.episodesInteractor = episodesInteractor
        setupSearchText()
    }

    deinit { searchTask?.cancel() }

    func fetchPodcasts() async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil
        do {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let results: [Podcast]
            if query.count > 2 {
                results = try await podcastsInteractor.searchPodcasts(forValue: query)
            } else {
                results = try await podcastsInteractor.fetchPodcasts()
            }
            guard !Task.isCancelled, requestID == id else { return }
            podcasts = results.map(PodcastViewModel.init(podcast:))
        } catch {
            if !Task.isCancelled && requestID == id {
                errorMessage = "Unable to load podcasts. \(error.localizedDescription)"
            }
        }
        if requestID == id { isLoading = false }
    }

    func favorite(podcast: PodcastViewModel) async {
        do {
            _ = try await podcastsInteractor.favorite(podcast: Podcast(podcastViewModel: podcast))
            await fetchFavorites()
        } catch { errorMessage = error.localizedDescription }
    }

    func unfavorite(podcast: PodcastViewModel) async {
        do {
            _ = try await podcastsInteractor.unfavorite(podcast: Podcast(podcastViewModel: podcast))
            await fetchFavorites()
        } catch { errorMessage = error.localizedDescription }
    }

    func fetchFavorites() async {
        do {
            favoritePodcasts = try await podcastsInteractor.fetchFavorites().map(PodcastViewModel.init(podcast:))
        } catch { errorMessage = error.localizedDescription }
    }

    func isfavorite(podcast: PodcastViewModel) async -> Bool {
        do {
            return try await podcastsInteractor.isFavorite(podcast: Podcast(podcastViewModel: podcast))
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func setupSearchText() {
        searchSubscription = $searchText
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(333), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.searchTask?.cancel()
                self.searchTask = Task { [weak self] in await self?.fetchPodcasts() }
            }
    }
}
