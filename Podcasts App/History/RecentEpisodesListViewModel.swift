import Foundation
import Resolver

class RecentEpisodesListViewModel {
    
    @Injected var persistanceManager: PodcastsPersistantManager

    private var episodeListViewModel = [EpisodeViewModel]()
    private var filteredEpisodesList = [EpisodeViewModel]()
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodesList : self.episodeListViewModel
    }
    
    var isSearching: Bool  = false {
        didSet {
            fetchEpisodes()
        }
    }
    
        
    func fetchEpisodes() {
        let x = persistanceManager.fetchAllRecentlyPlayedPodcasts()
        episodeListViewModel = x?.map{ EpisodeViewModel(episode: $0)} ?? [EpisodeViewModel]()
    }
    
    func episode(atIndex index: Int) -> EpisodeViewModel {
        return isSearching ? filteredEpisodesList[index] : episodeListViewModel[index]
    }
    
    func search(forValue value: String) {
        isSearching = value.count > 0
        
        self.filteredEpisodesList = self.episodeListViewModel.filter { (episode) -> Bool in
            (episode.title.lowercased().contains(value.lowercased()))
        }
    }
    
    func finishSearch() {
        isSearching = false
    }
}
