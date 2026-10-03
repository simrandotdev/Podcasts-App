import Foundation
import Resolver
import Combine

/// The listening history, most recently played first, for the Recently Played tab, the Home shelf and
/// Downloads. Reloads whenever an episode is played.
@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var episodes: [EpisodeViewModel] = []
    @Published private(set) var errorMessage: String?

    private let episodesManager: EpisodesManaging
    private let downloadManager: DownloadManager
    private var subscription: AnyCancellable?

    /// - Parameter downloadManager: Defaults to the app's shared download manager.
    init(episodesManager: EpisodesManaging = Resolver.resolve(),
         downloadManager: DownloadManager? = nil) {
        self.episodesManager = episodesManager
        self.downloadManager = downloadManager ?? .shared
        subscription = episodesManager.historyDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { await self?.fetchHistory() }
            }
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
