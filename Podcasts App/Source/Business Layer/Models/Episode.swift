import Foundation
import FeedKit
import GRDB

struct Episode : Codable, FetchableRecord, PersistableRecord {
    
    let title: String
    let subtitle: String
    let pubDate: Date
    let description: String
    let author: String
    let streamUrl: String
    var fileUrl: String?
    var imageUrl: String?
    
    init(feedItem: RSSFeedItem) {
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
        self.title = feedItem.title ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? ""
        self.author = feedItem.iTunes?.iTunesAuthor ?? ""
        self.imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href
        self.subtitle = feedItem.iTunes?.iTunesSubtitle ?? ""
        
    }
    
    init(episodeViewModel: EpisodeViewModel) {
        self.streamUrl = episodeViewModel.streamUrl
        self.title = episodeViewModel.title
        self.pubDate = episodeViewModel.pubDate
        self.description = episodeViewModel.description
        self.author = episodeViewModel.author
        self.imageUrl = episodeViewModel.imageUrl
        self.subtitle = episodeViewModel.subtitle
    }
}
