import Foundation

class FavoritePodcastRepository
{
    func favoritePodcast(podcast: Podcast)
    {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return }
        favoritePodcasts.append(podcast)
        let favoritePodcastsData = NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts)
        UserDefaults.standard.setValue(favoritePodcastsData, forKey: "favoritePodcasts")
    }
    
    func unfavoritePodcast(podcast: Podcast)
    {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return }
        let indexToDelete = indexOfPodcastToDelete(podcast: podcast, from: favoritePodcasts)
        if let indexToDelete = indexToDelete,
            indexToDelete >= 0 {
            favoritePodcasts.remove(at: indexToDelete)
        }
    }
    
    func fetchFavoritePodcasts() -> [Podcast]?
    {
        let podcastsData = UserDefaults.standard.data(forKey: "favoritePodcasts")
        let favoritePodcasts = NSKeyedUnarchiver.unarchiveObject(with: podcastsData ?? Data()) as? [Podcast] ?? [Podcast]()
        return favoritePodcasts
    }
    
    fileprivate
    func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int?
    {
        return podcasts.index(of: podcast)
    }
}
