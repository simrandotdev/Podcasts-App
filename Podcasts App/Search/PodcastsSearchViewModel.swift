import Foundation
import Combine
import Resolver

class PodcastsSearchViewModel {

    @Published var searchTerm: String = "podcast"
    @Published var podcasts = [PodcastViewModel]()
    
    @Injected private var api: APIService
    
    fileprivate var cancellable = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    
    private func setupSubscriptions() {
        
        $searchTerm
            .filter{ $0.count > 2 }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .sink { [searchPodcasts] value in
                Task {
                    try await searchPodcasts()
                }
            }
            .store(in: &cancellable)
    }
    
    
    func searchPodcasts() async throws {
        
        let podcastsResults = try await api.fetchPodcastsAsync(searchText: searchTerm)
        self.podcasts = podcastsResults.map{ PodcastViewModel(podcast: $0) }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        if index >= podcasts.count { return podcasts.last! }
        return podcasts[index]
    }
}
