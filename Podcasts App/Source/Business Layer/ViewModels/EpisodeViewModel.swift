import Foundation

class EpisodeViewModel {
    let title: String
    let subtitle: String
    let pubDate: Date
    let description: String
    let author: String
    let streamUrl: String
    var fileUrl: String?
    var imageUrl: String?
    
    // TODO: Remove HTML tags.
    var shortDescription: String {
        let array = Array(description)
        var string = description
        if array.count > 100 {
            string = String(array.dropLast(array.count - 100))
        }
        return string.removeHtmlTags().trimingLeadingSpaces()
    }
    
    var formattedDateString: String {
        return pubDate.formatted(date: .long, time: .omitted)
    }
    
    init(episode: Episode) {
        self.streamUrl = episode.streamUrl
        self.title = episode.title
        self.pubDate = episode.pubDate
        self.description = episode.description
        self.author = episode.author
        self.imageUrl = episode.imageUrl
        self.subtitle = episode.subtitle
    }
}
