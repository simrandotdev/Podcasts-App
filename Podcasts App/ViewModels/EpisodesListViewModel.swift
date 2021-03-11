import Foundation

class EpisodesListViewModel {
    var podcast: PodcastViewModel?
    var delegate: EpisodesListViewModelDelegate?
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodesList : self.episodeListViewModel
    }
    
    var isSearching: Bool  = false {
        didSet {
            guard let podcast = self.podcast else { return }
            fetchEpisodes(forPodcast: self.podcast ?? podcast)
        }
    }
    
    private var episodeListViewModel = [EpisodeViewModel]()
    private var filteredEpisodesList = [EpisodeViewModel]()
    private let api = APIService.shared

    
    func fetchEpisodes(forPodcast podcast: PodcastViewModel) {
        self.podcast = podcast
        api.fetchEpisodes(forPodcast: podcast.rssFeedUrl) { [weak self] (episodes) in
            DispatchQueue.main.async {
                self?.episodeListViewModel = episodes.map{ EpisodeViewModel(episode: $0) }
                self?.delegate?.onFetchEpisodesComplete()
            }
        }
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
