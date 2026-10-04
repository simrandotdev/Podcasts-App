import Foundation
import Observation
import Resolver

/// The listening history, most recently played first, for the Recently Played tab, the Home shelf and
/// Downloads. Reloads whenever an episode is played.
@MainActor
@Observable
final class HistoryViewModel {
    private(set) var episodes: [EpisodeViewModel] = []
    private(set) var errorMessage: String?

    private let episodesManager: EpisodesManaging
    private let downloadManager: DownloadManager
    @ObservationIgnored private var changesTask: Task<Void, Never>?

    /// - Parameter downloadManager: Defaults to the app's shared download manager.
    init(episodesManager: EpisodesManaging = Resolver.resolve(),
         downloadManager: DownloadManager? = nil) {
        self.episodesManager = episodesManager
        self.downloadManager = downloadManager ?? .shared
        // Subscribe now, so no change is missed, then reload after each one.
        let changes = episodesManager.historyChanges()
        changesTask = Task { [weak self] in
            for await _ in changes {
                await self?.fetchHistory()
            }
        }
    }

    deinit {
        changesTask?.cancel()
    }

    /// The Home screen's Recently Played shelf.
    var recentEpisodes: [EpisodeViewModel] { Array(episodes.prefix(10)) }

    func fetchHistory() async {
        errorMessage = nil
        do {
            let history = try await episodesManager.fetchHistory()
            episodes = history.map(EpisodeViewModel.init(episode:))
            // History can identify downloads saved before episode details were recorded.
            downloadManager.identifyDownloads(from: history)
        } catch {
            errorMessage = "Unable to load listening history. \(error.localizedDescription)"
            err("\(#function)", error.localizedDescription)
        }
    }
}
