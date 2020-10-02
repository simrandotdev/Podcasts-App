import Foundation
import FeedKit

class APIService {
    static let shared = APIService()
    private init() { }
    
    func fetchPodcast(searchText: String, completion: @escaping ([Podcast]) -> Void) {
        guard let url = URL(string:"https://podcasts-server.herokuapp.com?query=\(searchText)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                completion([])
            }
            
            do {
                guard let data = data else { return }
                let searchResults = try JSONDecoder().decode([Podcast].self, from: data)
                completion(searchResults)
            } catch let decodeErr {
                completion([])
                print("Failed to decode: ", decodeErr)
            }
        }.resume()
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

