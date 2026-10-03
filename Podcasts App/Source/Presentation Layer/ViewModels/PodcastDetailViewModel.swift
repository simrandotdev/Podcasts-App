import Foundation
import Resolver

/// Backs `EpisodesScreen`: one podcast's episodes, newest first, and whether it's a favorite.
@MainActor
final class PodcastDetailViewModel: ObservableObject {
    let podcast: PodcastViewModel
    @Published private(set) var episodes: [EpisodeViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFavorite = false
    @Published private(set) var isUpdatingFavorite = false

    private let podcastsManager: PodcastsManaging
    private let episodesManager: EpisodesManaging
    private let downloadManager: DownloadManager
    private let newEpisodesManager: NewEpisodesManager

    /// - Parameters:
    ///   - downloadManager: Defaults to the app's shared download manager.
    ///   - newEpisodesManager: Defaults to the app's shared new-episodes manager.
    init(podcast: PodcastViewModel,
         podcastsManager: PodcastsManaging = Resolver.resolve(),
         episodesManager: EpisodesManaging = Resolver.resolve(),
         downloadManager: DownloadManager? = nil,
         newEpisodesManager: NewEpisodesManager? = nil) {
        self.podcast = podcast
        self.podcastsManager = podcastsManager
        self.episodesManager = episodesManager
        self.downloadManager = downloadManager ?? .shared
        self.newEpisodesManager = newEpisodesManager ?? .shared
    }

    /// The episode "Tune In" plays.
    var latestEpisode: EpisodeViewModel? { episodes.first }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await episodesManager.fetchEpisodes(forFeedUrl: podcast.rssFeedUrl)
            episodes = fetched.map(EpisodeViewModel.init(episode:))
            // The episode list can identify downloads saved before episode details were recorded.
            downloadManager.identifyDownloads(from: fetched)
            // Opening a podcast clears its NEW badge and its Fresh on Air episodes.
            if !fetched.isEmpty {
                newEpisodesManager.markSeen(podcast.rssFeedUrl, episodeUrls: fetched.map(\.streamUrl))
            }
        } catch {
            errorMessage = "Unable to load episodes. \(error.localizedDescription)"
            err("\(#function)", error.localizedDescription)
        }
        isLoading = false
        await refreshFavorite()
    }

    func toggleFavorite() async {
        isUpdatingFavorite = true
        defer { isUpdatingFavorite = false }
        let model = Podcast(podcastViewModel: podcast)
        do {
            if isFavorite {
                try await podcastsManager.unfavorite(podcast: model)
            } else {
                try await podcastsManager.favorite(podcast: model)
            }
        } catch {
            errorMessage = "Unable to update favorites. \(error.localizedDescription)"
        }
        await refreshFavorite()
    }

    private func refreshFavorite() async {
        do {
            isFavorite = try await podcastsManager.isFavorite(podcast: Podcast(podcastViewModel: podcast))
        } catch {
            err("\(#function)", error.localizedDescription)
        }
    }
}
