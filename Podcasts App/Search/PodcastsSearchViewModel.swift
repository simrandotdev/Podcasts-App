import Foundation
import Combine
import Resolver
import BaadalKit
import CloudKit

class PodcastsSearchViewModel {

    @Published var searchTerm: String = "podcast"
    @Published var podcasts = [PodcastViewModel]()
    @Published var favoritePodcasts : [Podcast] = []
    @Published var isFavorite: Bool = false
    
    private let bkRecordTypeFavoritePodcasts = "FavoritePodcasts"
    
    @Injected private var api: APIService
    @Injected private var favoritePodcastRepository: PodcastsPersistantManager
    @Injected private var bkManager: BaadalManager
    
    fileprivate var cancellable = Set<AnyCancellable>()
    
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
        
        Task {
            try await fetchFavoritePodcasts()
        }
    }
    
    
    func fetchPodcastsAsync() async throws {        
        let podcastsResults = try await api.fetchPodcastsAsync(searchText: searchTerm)
        self.podcasts = podcastsResults.map{ PodcastViewModel(podcast: $0) }
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        if index >= podcasts.count { return podcasts.last! }
        return podcasts[index]
    }
    
    func fetchFavoritePodcasts() async throws {

        favoritePodcasts = try await bkManager.fetch(recordType: bkRecordTypeFavoritePodcasts)
            .compactMap({ record in
                guard let author = record.object(forKey: "author") as? String,
                      let title = record.object(forKey: "title") as? String,
                      let image = record.object(forKey: "image") as? String,
                      let totalEpisodes = record.object(forKey: "totalEpisodes") as? Int,
                      let rssFeedUrl = record.object(forKey: "rssFeedUrl") as? String else {
                          return nil
                      }
                
                return Podcast(recordId: record.recordID.recordName,
                               title: title,
                               author: author,
                               image: image,
                               totalEpisodes: totalEpisodes,
                               rssFeedUrl: rssFeedUrl)
            })
        
    }

    func favoritePodcast(_ podcast: Podcast) async throws {

        let favoritePodcastRecord = CKRecord(recordType: bkRecordTypeFavoritePodcasts) // TODO: Extract into some place common
        favoritePodcastRecord.setValue(podcast.author, forKey: "author")
        favoritePodcastRecord.setValue(podcast.title, forKey: "title")
        favoritePodcastRecord.setValue(podcast.image, forKey: "image")
        favoritePodcastRecord.setValue(podcast.totalEpisodes, forKey: "totalEpisodes")
        favoritePodcastRecord.setValue(podcast.rssFeedUrl, forKey: "rssFeedUrl")

        _ = try await bkManager.save(record: favoritePodcastRecord)
    }

    func unfavoritePodcast(_ podcast: Podcast) {

        let podcastToUnfavorite = favoritePodcasts.first { $0.recordId == podcast.recordId }
        guard let unfavorite = podcastToUnfavorite else { return }

        Task {
            try await bkManager.delete(BKFavoritePodcast(podcast: unfavorite))
        }
    }

    func isFavorite(_ podcast: Podcast) async throws {
        try await fetchFavoritePodcasts()
        self.isFavorite =  self.favoritePodcasts.contains(podcast)
    }
    
    
    
    
    
    
//    func isFavorite(_ podcast: Podcast) -> Bool {
//        return favoritePodcastRepository.isFavorite(podcast: podcast)
//    }
//
//    func fetchFavoritePodcasts() {
//        favoritePodcasts = favoritePodcastRepository.fetchFavoritePodcasts()
//    }
//
//    func unfavoritePodcast(_ podcast: Podcast) {
//        favoritePodcasts = favoritePodcastRepository.unfavoritePodcast(podcast: podcast)
//    }
//
//    func favoritePodcast(_ podcast: Podcast) {
//        favoritePodcasts = favoritePodcastRepository.favoritePodcast(podcast: podcast)
//    }
    
}


struct BKFavoritePodcast : RecordIDItem {
    
    var recordId: CKRecord.ID
    var title: String
    var author: String
    var image: String
    var totalEpisodes: Int
    var rssFeedUrl: String
    
    init(podcast: Podcast) {
        recordId = CKRecord.ID(recordName: podcast.recordId ?? "")
        title = podcast.title ?? ""
        author = podcast.author ?? ""
        image = podcast.image ?? ""
        totalEpisodes = podcast.totalEpisodes ?? 0
        rssFeedUrl = podcast.rssFeedUrl ?? ""
    }
}
