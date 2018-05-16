import Foundation
import Alamofire

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
                    print("Failed to contact yahoo", err)
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
}
