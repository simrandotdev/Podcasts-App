import Foundation
import FeedKit
import RxSwift
import RxCocoa

class APIService {
    static let shared = APIService()
    
    private init() { }
    
    func fetchPodcasts(searchText: String) -> Observable<[Podcast]> {
        let BASEURL = "https://podcasts-server.herokuapp.com"
        let searchURLString = "\(BASEURL)?query=\(searchText)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: searchURLString) else {
            fatalError("Failed to create a URL")
        }
        let request = URLRequest(url: url)
        
        return URLSession.shared
            .rx
            .data(request: request)
            .map { data in
                try JSONDecoder().decode([Podcast].self, from: data)
            }
    }
    
    func fetchEpisodes(forPodcast rssUrl:String) -> Observable<[Episode]> {
        let url = URL(string: rssUrl)!
        return Observable.create { (observer) -> Disposable in
            DispatchQueue.global(qos: .background).async {
                let parser = FeedParser(URL: url)
                parser.parseAsync { (result) in
                    switch result {
                    case .success(let feed):
                        guard let feed = feed.rssFeed else { return }
                        let episodes = feed.toEpisodes()
                        observer.onNext(episodes)
                    case .failure(let error):
                        print("Failed to parse XML feed:", error)
                        observer.onError(APIError.failedToParseRss)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    
    func fetchEpisodes(forPodcast rssUrl: String, completion: @escaping ([Episode]) -> Void) {
        guard let url = URL(string: rssUrl) else { return }
        DispatchQueue.global(qos: .background).async {
            let parser = FeedParser(URL: url)
            parser.parseAsync { (result) in
                switch result {
                case .success(let feed):
                    guard let feed = feed.rssFeed else { return }
                    let episodes = feed.toEpisodes()
                    completion(episodes)
                case .failure(let error):
                    print("Failed to parse XML feed:", error)
                    return
                }
            }
        }
    }
}


enum APIError: Error {
    case failedToParseRss
    case failedToParseJSON
}
