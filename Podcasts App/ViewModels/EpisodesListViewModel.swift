import Foundation

protocol EpisodesListViewModelProtocol {
    func didFetchedEpisodes()
}

class EpisodesListViewModel {
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodesList : self.episodeListViewModel
    }
    
    private var episodeListViewModel = [EpisodeViewModel]()
    private var filteredEpisodesList = [EpisodeViewModel]()
    private var isSearching = false
    
    var podcast: PodcastViewModel?
    
    var delegate: EpisodesListViewModelProtocol?
    
    private let api = APIService.shared
    
    
    func getEpisodes(forPodcast podcast: PodcastViewModel) {
        self.podcast = podcast
        api.fetchEpisodes(forPodcast: podcast.title) { [weak self] (episodes) in
            DispatchQueue.main.async {
                self?.episodeListViewModel = episodes.map{ EpisodeViewModel(episode: $0) }
                self?.delegate?.didFetchedEpisodes()
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
}
