import Foundation
import Combine
import Resolver

class PodcastsSearchViewModel {

    @Published var searchTerm: String = "podcast"
    @Published var podcasts = [PodcastViewModel]()
    @Published var favoritePodcasts : [Podcast] = []
    @Published var isFavorite: Bool = false
    
    @Injected private var api: APIService
    @Injected private var favoritePodcastLocalService: PodcastsPersistantManager
    @Injected private var favoritePodcastCloudService: FavoritePodcastsService
    
    fileprivate var cancellable = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        Task {
            try await fetchFavoritePodcasts()
        }
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
        
        favoritePodcastCloudService.$podcasts
            .sink { podcasts in
                self.favoritePodcasts = podcasts
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
    
    func fetchFavoritePodcasts() async throws {
        try await favoritePodcastCloudService.fetchFavoritePodcasts()
    }

    func favoritePodcast(_ podcast: Podcast) async throws {

        try await favoritePodcastCloudService.favoritePodcast(podcast)
    }

    func unfavoritePodcast(_ podcast: Podcast) async throws {

        try await favoritePodcastCloudService.unfavoritePodcast(podcast)
    }

    func isFavorite(_ podcast: Podcast) async throws {
        
        isFavorite = try await favoritePodcastCloudService.isFavorite(podcast)
    }
}
