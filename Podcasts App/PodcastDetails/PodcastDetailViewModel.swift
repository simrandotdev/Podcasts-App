import Foundation
import Resolver

class PodcastDetailViewModel {
    
    @Injected var api: APIService
    
    private var podcast: PodcastViewModel?
    private var episodes = [EpisodeViewModel]()
    private var filteredEpisodes = [EpisodeViewModel]()
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodes : episodes
    }
    
    var isSearching: Bool  = false {
        didSet {
            guard let podcast = self.podcast else { return }
            Task {
                try await fetchEpisodes(forPodcast: podcast)
            }
        }
    }
    
    func fetchEpisodes(forPodcast podcast: PodcastViewModel) async throws {
        self.podcast = podcast
        let episodesResult = try await api.fetchEpisodesAsync(forPodcast: podcast.rssFeedUrl)
        episodes = episodesResult.map{ EpisodeViewModel(episode: $0) }
    }
    
    func episode(atIndex index: Int) -> EpisodeViewModel {
        return episodesList[index]
    }
    
    func search(forValue value: String) {
        isSearching = value.count > 0
        
        if isSearching {
            filteredEpisodes = episodes.filter { $0.title.lowercased().contains(value.lowercased()) }
        }
    }
    
    func finishSearch() {
        isSearching = false
    }
}
