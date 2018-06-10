import Foundation

struct Episode : Codable
{
    let title: String?
    let pubDate: String?
    var imageUrl: String?
    let description: String?
    let content: String?
    let author: String?
    let enclosure: Enclosure?
    
    static let mockEpisodes = [Episode]()
}

struct Enclosure : Codable
{
    let duration: Int?
    let link: String?
    let type: String?
}
