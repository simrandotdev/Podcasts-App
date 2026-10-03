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
    let podcastFeedUrl: String?
    
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
        self.fileUrl = episode.fileUrl
        self.podcastFeedUrl = episode.podcastFeedUrl
    }
}

extension Episode {
    init(episodeViewModel: EpisodeViewModel) {
        self.init(title: episodeViewModel.title, subtitle: episodeViewModel.subtitle, pubDate: episodeViewModel.pubDate,
                  description: episodeViewModel.description, author: episodeViewModel.author,
                  streamUrl: episodeViewModel.streamUrl, fileUrl: episodeViewModel.fileUrl,
                  imageUrl: episodeViewModel.imageUrl, podcastFeedUrl: episodeViewModel.podcastFeedUrl)
    }
}
