import Foundation

class EpisodeViewModel {
    let title: String
    let pubDate: Date
    let description: String
    let author: String
    let streamUrl: String
    var fileUrl: String?
    var imageUrl: String?
    
    init(episode: Episode) {
        self.streamUrl = episode.streamUrl
        self.title = episode.title
        self.pubDate = episode.pubDate
        self.description = episode.description
        self.author = episode.author
        self.imageUrl = episode.imageUrl
    }
}
