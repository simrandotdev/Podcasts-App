import FeedKit

extension RSSFeed {
    
    /// - Parameter podcastFeedUrl: The feed's own URL, recorded on each episode so it can be
    ///   matched back to its podcast exactly.
    func toEpisodes(podcastFeedUrl: String? = nil) -> [Episode] {
        let imageUrl = iTunes?.iTunesImage?.attributes?.href
        
        var episodes = [Episode]() // blank Episode array
        items?.forEach({ (feedItem) in
            var episode = Episode(feedItem: feedItem, podcastFeedUrl: podcastFeedUrl)
            
            if episode.imageUrl == nil {
                episode.imageUrl = imageUrl
            }
            
            episodes.append(episode)
        })
        return episodes
    }
}
