import Foundation

struct Episode : Codable
{
    let title: String?
    let pubDate: String?
    var imageUrl: String?
    let description: String?
    let content: String?
    let author: String?
    var enclosure: Enclosure?
    
    static let mockEpisodes = [Episode]()
}

struct Enclosure : Codable
{
    let duration: Int?
    var link: String?
    let type: String?
}
