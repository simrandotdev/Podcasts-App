import Foundation

class FavoritePodcastRepository
{
    func favoritePodcast(podcast: Podcast) -> [Podcast]?
    {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return nil }
        if favoritePodcasts.contains(where: { podcast == $0 }) { return nil }
        
        favoritePodcasts.append(podcast)
        let favoritePodcastsData = NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts)
        UserDefaults.standard.setValue(favoritePodcastsData, forKey: "favoritePodcasts")
        return favoritePodcasts
    }
    
    func unfavoritePodcast(podcast: Podcast) -> [Podcast]?
    {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return nil }
        let indexToDelete = indexOfPodcastToDelete(podcast: podcast, from: favoritePodcasts)
        if let indexToDelete = indexToDelete,
            indexToDelete >= 0 {
            favoritePodcasts.remove(at: indexToDelete)
        }
        let favoritePodcastsData = NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts)
        UserDefaults.standard.setValue(favoritePodcastsData, forKey: "favoritePodcasts")
        return favoritePodcasts
    }
    
    func fetchFavoritePodcasts() -> [Podcast]?
    {
        let podcastsData = UserDefaults.standard.data(forKey: "favoritePodcasts")
        let favoritePodcasts = NSKeyedUnarchiver.unarchiveObject(with: podcastsData ?? Data()) as? [Podcast] ?? [Podcast]()
        return favoritePodcasts
    }
    
    func isFavorite(podcast: Podcast) -> Bool
    {
        let podcasts = fetchFavoritePodcasts()
        return podcasts?.contains(podcast) ?? false
    }
    
    fileprivate
    func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int?
    {
        return podcasts.index(of: podcast)
    }
}
