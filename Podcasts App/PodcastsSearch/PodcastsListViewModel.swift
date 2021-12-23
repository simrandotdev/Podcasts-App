import Foundation
import Combine

class PodcastsListViewModel {

    var searchTerm: String = ""
    
    private let api: APIService
    
    var podcasts = [PodcastViewModel]()
    
    init(podcasts: [Podcast] = [], api: APIService = APIService.shared) {
        self.podcasts = podcasts.map{ PodcastViewModel(podcast: $0) }
        self.api = api
    }
    
    
    func fetchPodcastsAsync(query: String = "podcast") async throws {
        var searchQuery = query
        if searchQuery.isEmpty {
            searchQuery = "podcast"
        }
        
        let podcastsResults = try await api.fetchPodcastsAsync(searchText: query)
        self.podcasts = podcastsResults.map{ PodcastViewModel(podcast: $0) }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        if index >= podcasts.count { return podcasts.last! }
        return podcasts[index]
    }
}
