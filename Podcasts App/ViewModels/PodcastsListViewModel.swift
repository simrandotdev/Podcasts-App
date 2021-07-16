import Foundation
import RxSwift
import RxCocoa

class PodcastsListViewModel {

    var searchTerm: String = ""
    
    private var disposeBag = DisposeBag()
    private let api: APIService
    
    private var podcastsPublishSubject = PublishSubject<[Podcast]>()
    var podcastsObserver: Observable<[Podcast]> { return podcastsPublishSubject.asObserver() }
    var podcasts = [PodcastViewModel]()
    
    init(podcasts: [Podcast] = [], api: APIService = APIService.shared) {
        self.podcasts = podcasts.map{ PodcastViewModel(podcast: $0) }
        self.api = api
    }
    
    func fetchPodcastsObservable(query: String = "podcast") {
        var searchQuery = query
        if searchQuery.isEmpty {
            searchQuery = "podcast"
        }
        
        api.fetchPodcasts(searchText: searchQuery)
            .subscribe(onNext: { podcasts in
                self.podcastsPublishSubject.onNext(podcasts)
                self.podcasts = podcasts.map{ PodcastViewModel(podcast: $0) }
            }).disposed(by: disposeBag)
    }
    
    
    func podcast(atIndex index: Int) -> PodcastViewModel {
        if index >= podcasts.count { return podcasts.last! }
        return podcasts[index]
    }
}
