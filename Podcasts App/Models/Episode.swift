import Foundation

struct Episode : Codable
{
    let title: String
    let pubDate: String
    let thumbnail: String
    let description: String
    let content: String
//    let enclosure: Enclosure
    
    static let mockEpisodes = [Episode]()
}

//struct Enclosure : Codable
//{
//    let link: String
//    let duration: Int
//    let type: String
//}