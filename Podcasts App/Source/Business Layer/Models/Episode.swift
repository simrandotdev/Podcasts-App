import Foundation
import FeedKit

struct Episode : Codable {

    let title: String
    let subtitle: String
    let pubDate: Date
    let description: String
    let author: String
    /// Identifies an episode everywhere: the queue, history, downloads and resume positions.
    let streamUrl: String
    var fileUrl: String?
    var imageUrl: String?
    /// RSS feed URL of the podcast this episode belongs to (a favorite's `rssFeedUrl`).
    /// Nil for history entries saved before it was recorded.
    var podcastFeedUrl: String?

    init(title: String, subtitle: String, pubDate: Date, description: String, author: String, streamUrl: String,
         fileUrl: String? = nil, imageUrl: String? = nil, podcastFeedUrl: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.pubDate = pubDate
        self.description = description
        self.author = author
        self.streamUrl = streamUrl
        self.fileUrl = fileUrl
        self.imageUrl = imageUrl
        self.podcastFeedUrl = podcastFeedUrl
    }

    init(feedItem: RSSFeedItem, podcastFeedUrl: String? = nil) {
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
        self.title = feedItem.title ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? ""
        self.author = feedItem.iTunes?.iTunesAuthor ?? ""
        self.imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href
        self.subtitle = feedItem.iTunes?.iTunesSubtitle ?? ""
        self.podcastFeedUrl = podcastFeedUrl
    }
}
