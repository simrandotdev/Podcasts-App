import Foundation
import Observation
import Resolver

/// Backs the Home tab (`PodcastsScreen`): trending podcasts, or search results while searching.
/// Searching starts after more than 2 characters, 333 ms after typing stops.
///
/// On launch it shows the stations saved from the last visit until the latest ones load, because the
/// On Air API can take a while to wake up. While it shows saved stations, it retries a failed load.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var podcasts: [PodcastViewModel] = []
    var searchText = "" {
        didSet {
            if searchText != oldValue { scheduleSearch() }
        }
    }
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// True while `podcasts` are the stations saved from the last visit rather than the latest ones.
    private(set) var isShowingSavedStations = false

    private let podcastsManager: PodcastsManaging
    /// How long to wait before each retry while saved stations are showing.
    private let retryDelays: [TimeInterval]
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var requestID = UUID()

    init(podcastsManager: PodcastsManaging = Resolver.resolve(), retryDelays: [TimeInterval] = [5, 15]) {
        self.podcastsManager = podcastsManager
        self.retryDelays = retryDelays
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
            isShowingSavedStations = false
        } catch {
            if !Task.isCancelled && requestID == id {
                errorMessage = "Unable to load podcasts. \(error.localizedDescription)"
            }
        }
        if requestID == id { isLoading = false }
    }

    /// Loads the list when the screen appears. The first time, saved stations show right away. While they're
    /// showing, a load that fails is retried after each of `retryDelays`.
    func loadIfNeeded() async {
        if podcasts.isEmpty, !isSearching {
            let saved = await podcastsManager.cachedPodcasts()
            if podcasts.isEmpty, !saved.isEmpty {
                podcasts = saved.map(PodcastViewModel.init(podcast:))
                isShowingSavedStations = true
            }
        }
        guard podcasts.isEmpty || isShowingSavedStations else { return }
        await fetchPodcasts()
        for delay in retryDelays {
            guard isShowingSavedStations, errorMessage != nil, !isSearching else { return }
            try? await Task.sleep(for: .seconds(delay))
            // Leaving the screen cancels the wait. Saved stations are still showing, so the next visit loads again.
            guard !Task.isCancelled, isShowingSavedStations, !isSearching else { return }
            await fetchPodcasts()
        }
    }

    /// Searches 333 ms after typing stops. Each change cancels the wait, or the search, started before it.
    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(333))
            guard !Task.isCancelled else { return }
            await self?.fetchPodcasts()
        }
    }
}
