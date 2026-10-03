import Foundation
import Resolver
import Combine

/// Backs the Home tab (`PodcastsScreen`): popular podcasts, or search results while searching.
/// Searching starts after more than 2 characters, 333 ms after typing stops.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var podcasts: [PodcastViewModel] = []
    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let podcastsManager: PodcastsManaging
    private var searchSubscription: AnyCancellable?
    private var searchTask: Task<Void, Never>?
    private var requestID = UUID()

    init(podcastsManager: PodcastsManaging = Resolver.resolve()) {
        self.podcastsManager = podcastsManager
        setupSearchText()
    }

    deinit { searchTask?.cancel() }

    var isSearching: Bool { !searchText.isEmpty }

    func fetchPodcasts() async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil
        do {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let results: [Podcast]
            if query.count > 2 {
                results = try await podcastsManager.searchPodcasts(forValue: query)
            } else {
                results = try await podcastsManager.fetchPodcasts()
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

    /// Loads the list the first time the screen appears.
    func loadIfNeeded() async {
        if podcasts.isEmpty { await fetchPodcasts() }
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
