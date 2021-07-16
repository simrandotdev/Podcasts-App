import Foundation
import RxSwift
import RxRelay

class EpisodesListViewModel {
    var podcast: PodcastViewModel?
    
    var episodesPublishSubject = BehaviorRelay<[EpisodeViewModel]>(value: [])
    var filteredEpisodesPublishSubject = BehaviorRelay<[EpisodeViewModel]>(value: [])
    
    var episodesList: [EpisodeViewModel] {
        return self.isSearching ? self.filteredEpisodesPublishSubject.value : episodesPublishSubject.value
    }
    
    private let bag = DisposeBag()
    
    var isSearching: Bool  = false {
        didSet {
            guard let podcast = self.podcast else { return }
            fetchEpisodes(forPodcast: podcast)
        }
    }
    
    private let api = APIService.shared
    
    func fetchEpisodes(forPodcast podcast: PodcastViewModel) {
        self.podcast = podcast
        api.fetchEpisodes(forPodcast: podcast.rssFeedUrl)
            .subscribe(onNext: { [weak self] episodes in
                DispatchQueue.main.async {
                    self?.episodesPublishSubject.accept(episodes.map{ EpisodeViewModel(episode: $0) })
                }
            }).disposed(by: bag)
    }
    
    func episode(atIndex index: Int) -> EpisodeViewModel {
        return episodesList[index]
    }
    
    func search(forValue value: String) {
        isSearching = value.count > 0
        
        episodesPublishSubject.map { episodes in
            episodes.filter { $0.title.lowercased().contains(value.lowercased()) }
        }.subscribe(onNext: {
            self.filteredEpisodesPublishSubject.accept($0)
        }).disposed(by: bag)
    }
    
    func finishSearch() {
        isSearching = false
    }
}
