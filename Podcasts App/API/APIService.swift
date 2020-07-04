import Foundation
import Alamofire
import FeedKit

class APIService
{
    static let shared = APIService()
    private init() { }
    
    func fetchPodcast(searchText: String, completion: @escaping ([Podcast]) -> Void)
    {
        let url = "https://itunes.apple.com/search"
        let parameters = ["term": searchText, "media": "podcast"]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseData { (dataResponse) in
                if let err = dataResponse.error
                {
                    print("Failed to contact ", err)
                    return
                }
                
                guard let data = dataResponse.data else { return }
                
                do
                {
                    let searchResults = try JSONDecoder().decode(SearchResults.self, from: data)
                    completion(searchResults.results)
                } catch let decodeErr {
                    print("Failed to decode: ", decodeErr)
                }
        }
    }
    
    func fetchEpisodes(forPodcast rssUrl: String, completion: @escaping ([Episode]) -> Void)
    {
        let secureFeedUrl = rssUrl.contains("https") ? rssUrl : rssUrl.replacingOccurrences(of: "http", with: "https")
        
        guard let url = URL(string: rssUrl) else { return }
        
        DispatchQueue.global(qos: .background).async {
            print("Before parser")
            let parser = FeedParser(URL: url)
            print("After parser")
            
            parser?.parseAsync(result: { (result) in
                print("Successfully parse feed:", result.isSuccess)
                
                if let err = result.error {
                    print("Failed to parse XML feed:", err)
                    return
                }
                
                guard let feed = result.rssFeed else { return }
                
                let episodes = feed.toEpisodes()
                completion(episodes)
            })
        }
    }
}

struct FeedResponse : Codable
{
    let items: [Episode]
}
