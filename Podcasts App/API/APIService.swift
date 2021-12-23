import Foundation
import FeedKit
import RxSwift
import RxCocoa

class APIService {
    static let shared = APIService()
    
    private init() { }
    
    func fetchPodcastsAsync(searchText: String) async throws -> [Podcast] {
        let BASEURL = "https://podcasts-server.herokuapp.com"
        let searchURLString = "\(BASEURL)?query=\(searchText)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: searchURLString) else {
            fatalError("Failed to create a URL")
        }
        let request = URLRequest(url: url)
        
        return try await withCheckedThrowingContinuation({ continutation in
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                
                if let _ = error {
                    continutation.resume(throwing: APIError.invalidRequest)
                    return
                }
                
                do {
                    guard let data = data else {
                        continutation.resume(throwing: APIError.invalidRequest)
                        return
                    }
                    
                    let podcasts = try JSONDecoder().decode([Podcast].self, from: data)
                    continutation.resume(returning: podcasts)
                } catch {
                    continutation.resume(throwing: APIError.invalidRequest)
                }
                
                
            }.resume()
        })
    }
    
    
    func fetchEpisodesAsync(forPodcast rssUrl: String) async throws -> [Episode] {
        guard let url = URL(string: rssUrl) else { return  [] }
        
        return try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .background).async {
                let parser = FeedParser(URL: url)
                parser.parseAsync { (result) in
                    switch result {
                    case .success(let feed):
                        guard let feed = feed.rssFeed else { return }
                        let episodes = feed.toEpisodes()
                        cont.resume(returning: episodes)
                    case .failure(let error):
                        print("Failed to parse XML feed:", error)
                        cont.resume(throwing: APIError.invalidRequest)
                    }
                }
            }
        }
    }
    
    
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
}


enum APIError: Error {
    case failedToParseRss
    case failedToParseJSON
    case invalidRequest
}
