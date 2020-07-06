import Foundation
import Alamofire
import FeedKit

class APIService {
    static let shared = APIService()
    private init() { }
    
    func fetchPodcast(searchText: String, completion: @escaping ([Podcast]) -> Void) {
        let url = "https://itunes.apple.com/search"
        let parameters = ["term": searchText, "media": "podcast"]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseData { (dataResponse) in
                do {
                    if let err = dataResponse.error {
                        print("Failed to contact ", err)
                        return
                    }
                    guard let data = dataResponse.data else { return }
                    let searchResults = try JSONDecoder().decode(SearchResults.self, from: data)
                    completion(searchResults.results)
                } catch let decodeErr {
                    print("Failed to decode: ", decodeErr)
                }
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

