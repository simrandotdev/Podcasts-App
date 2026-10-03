import CoreData

/// A favorite (preset) podcast, keyed by `rssFeedUrl`.
@objc(FavoritePodcastEntity)
final class FavoritePodcastEntity: NSManagedObject {
    @NSManaged var rssFeedUrl: String
    @NSManaged var recordId: String?
    @NSManaged var title: String?
    @NSManaged var author: String?
    @NSManaged var image: String?
    @NSManaged var totalEpisodes: NSNumber?
    /// Presets are numbered in the order they were saved.
    @NSManaged var favoritedAt: Date

    static let entityName = "FavoritePodcastEntity"

    /// Every favorite, in preset order.
    static func allRequest() -> NSFetchRequest<FavoritePodcastEntity> {
        let request = NSFetchRequest<FavoritePodcastEntity>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FavoritePodcastEntity.favoritedAt), ascending: true)]
        return request
    }

    static func request(rssFeedUrl: String) -> NSFetchRequest<FavoritePodcastEntity> {
        let request = NSFetchRequest<FavoritePodcastEntity>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(FavoritePodcastEntity.rssFeedUrl), rssFeedUrl)
        request.fetchLimit = 1
        return request
    }

    /// Copies the podcast's details. Leaves `favoritedAt` alone so an existing preset keeps its number.
    func update(from podcast: Podcast) {
        rssFeedUrl = podcast.rssFeedUrl ?? ""
        recordId = podcast.recordId
        title = podcast.title
        author = podcast.author
        image = podcast.image
        totalEpisodes = podcast.totalEpisodes.map { NSNumber(value: $0) }
    }

    var podcast: Podcast {
        Podcast(recordId: recordId, title: title, author: author, image: image,
                totalEpisodes: totalEpisodes?.intValue, rssFeedUrl: rssFeedUrl)
    }
}
