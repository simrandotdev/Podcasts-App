import CoreData

/// An episode in the listening history, keyed by `streamUrl`.
@objc(HistoryEpisodeEntity)
final class HistoryEpisodeEntity: NSManagedObject {
    @NSManaged var streamUrl: String
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var pubDate: Date
    /// The episode's `description`, which `NSManagedObject` already uses.
    @NSManaged var episodeDescription: String
    @NSManaged var author: String
    @NSManaged var fileUrl: String?
    @NSManaged var imageUrl: String?
    /// Nil for history saved before feed URLs were recorded.
    @NSManaged var podcastFeedUrl: String?
    /// History is listed newest first by this.
    @NSManaged var lastPlayedAt: Date

    static let entityName = "HistoryEpisodeEntity"

    /// The whole history, most recently played first.
    static func allRequest() -> NSFetchRequest<HistoryEpisodeEntity> {
        let request = NSFetchRequest<HistoryEpisodeEntity>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(HistoryEpisodeEntity.lastPlayedAt), ascending: false)]
        return request
    }

    static func request(streamUrl: String) -> NSFetchRequest<HistoryEpisodeEntity> {
        let request = NSFetchRequest<HistoryEpisodeEntity>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(HistoryEpisodeEntity.streamUrl), streamUrl)
        request.fetchLimit = 1
        return request
    }

    /// Copies every detail of the episode, replacing what was saved before.
    func update(from episode: Episode) {
        streamUrl = episode.streamUrl
        title = episode.title
        subtitle = episode.subtitle
        pubDate = episode.pubDate
        episodeDescription = episode.description
        author = episode.author
        fileUrl = episode.fileUrl
        imageUrl = episode.imageUrl
        podcastFeedUrl = episode.podcastFeedUrl
    }

    var episode: Episode {
        Episode(title: title, subtitle: subtitle, pubDate: pubDate, description: episodeDescription, author: author,
                streamUrl: streamUrl, fileUrl: fileUrl, imageUrl: imageUrl, podcastFeedUrl: podcastFeedUrl)
    }
}
