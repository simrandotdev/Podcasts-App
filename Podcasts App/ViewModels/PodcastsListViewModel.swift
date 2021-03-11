import Foundation

class PodcastsListViewModel {

    var podcastsViewModel = [PodcastViewModel]() { didSet { self.delegate?.onPodcastsFetchComplete() } }
    var searchTerm: String = ""
    var delegate: PodcastsListViewModelDelegate?
    var numberOfPodcasts: Int { get { podcastsViewModel.count } }
    
    private let api: APIService
    
    init(podcasts: [Podcast] = [], api: APIService = APIService.shared) {
        podcastsViewModel = podcasts.map{ PodcastViewModel(podcast: $0) }
        self.api = api
    }
    
    func fetchPodcasts(query: String = "podcast") {
        api.fetchPodcast(searchText: query) { [weak self] (podcasts) in
            DispatchQueue.main.async { [weak self] in
                self?.podcastsViewModel = podcasts.map{ PodcastViewModel(podcast: $0) }
            }
        }
    }
    
    func searchPodcasts(podcast: String) {
        self.searchTerm = podcast
        if podcast.count > 2 { self.fetchPodcasts(query: podcast) }
        else { self.self.fetchPodcasts(query: "podcast") }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel { podcastsViewModel[index] }
}
