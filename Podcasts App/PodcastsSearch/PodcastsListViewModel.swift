import Foundation
import Combine
import Resolver

class PodcastsListViewModel {

    @Published var searchTerm: String = "podcast"
    @Published var podcasts = [PodcastViewModel]()
    fileprivate var cancellable = Set<AnyCancellable>()
    
    @Injected var api: APIService
    
    init(podcasts: [Podcast] = [], api: APIService = APIService.shared) {
        self.podcasts = podcasts.map{ PodcastViewModel(podcast: $0) }
        self.api = api
        
        $searchTerm
            .filter{ $0.count > 2 }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .sink { [fetchPodcastsAsync] value in
                Task {
                    try await fetchPodcastsAsync()
                }
            }
            .store(in: &cancellable)
    }
    
    
    func fetchPodcastsAsync() async throws {        
        let podcastsResults = try await api.fetchPodcastsAsync(searchText: searchTerm)
        self.podcasts = podcastsResults.map{ PodcastViewModel(podcast: $0) }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        if index >= podcasts.count { return podcasts.last! }
        return podcasts[index]
    }
}
