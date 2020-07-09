import Foundation

protocol SearchPodcastViewModelDelegate {
    func didFetchedPodcasts()
}


class SearchPodcastViewModel {
    
    var podcastsViewModel = [PodcastViewModel]()
    private let api = APIService.shared
    private var timer : Timer?
    
    var searchTerm: String = ""
    
    var delegate: SearchPodcastViewModelDelegate?
    var numberOfPodcasts: Int { get { podcastsViewModel.count } }
    
    
    init() { }
    
    init(podcasts: [Podcast]) {
        podcastsViewModel = podcasts.map{ PodcastViewModel(podcast: $0) }
        DispatchQueue.main.async {[weak self] in
            self?.delegate?.didFetchedPodcasts()
        }
    }
    
    
    func fetchPodcasts(query: String = "podcast") {
        api.fetchPodcast(searchText: query) { [weak self] (podcasts) in
            self?.podcastsViewModel = podcasts.map{ PodcastViewModel(podcast: $0) }
            self?.delegate?.didFetchedPodcasts()
        }
    }
    
    func searchPodcasts(podcast: String) {
        self.searchTerm = podcast
        if podcast.count > 0 {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (_) in
                self.fetchPodcasts(query: podcast)
            })
        }
        else { self.self.fetchPodcasts(query: "podcast") }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        return podcastsViewModel[index]
    }
}
