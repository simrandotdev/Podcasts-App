import Foundation

class RecentEpisodesListViewModel {
    var podcast: PodcastViewModel?
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodesList : self.episodeListViewModel
    }
    
    var isSearching: Bool  = false {
        didSet {
            fetchEpisodes()
        }
    }
    
    private var episodeListViewModel = [EpisodeViewModel]()
    private var filteredEpisodesList = [EpisodeViewModel]()
    private let persistanceManager = PodcastsPersistantManager()

    
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
