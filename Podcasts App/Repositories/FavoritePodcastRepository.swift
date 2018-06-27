import Foundation

class FavoritePodcastRepository
{
    fileprivate let favoriteEpisodeKey = "favoritePodcasts"
    fileprivate let downloadedEpisodeKey = "downloadedEpisodeKey"
    
    func favoritePodcast(podcast: Podcast) -> [Podcast]?
    {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return nil }
        if favoritePodcasts.contains(where: { podcast == $0 }) { return nil }
        
        favoritePodcasts.append(podcast)
        let favoritePodcastsData = NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts)
        UserDefaults.standard.setValue(favoritePodcastsData, forKey: favoriteEpisodeKey)
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
        UserDefaults.standard.setValue(favoritePodcastsData, forKey: favoriteEpisodeKey)
        return favoritePodcasts
    }
    
    func fetchFavoritePodcasts() -> [Podcast]?
    {
        let podcastsData = UserDefaults.standard.data(forKey: favoriteEpisodeKey)
        let favoritePodcasts = NSKeyedUnarchiver.unarchiveObject(with: podcastsData ?? Data()) as? [Podcast] ?? [Podcast]()
        return favoritePodcasts
    }
    
    func isFavorite(podcast: Podcast) -> Bool
    {
        let podcasts = fetchFavoritePodcasts()
        return podcasts?.contains(podcast) ?? false
    }
    
    func downloadEpisode(episode: Episode) {
        do
        {
            var episodes = downloadedEpisodes()
            episodes.append(episode)
            
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: downloadedEpisodeKey)
        }
        catch let encodeErr
        {
            print("Failed to encode episode: ", encodeErr)
        }
    }
    
    func downloadedEpisodes() -> [Episode]
    {
        guard let data = UserDefaults.standard.data(forKey: downloadedEpisodeKey) else { return [Episode]()}
        do
        {
            let episodes = try JSONDecoder().decode([Episode].self, from: data)
            return episodes
        }
        catch let decodeErr
        {
            print("Error Decoding Episodes: ", decodeErr)
        }
        return [Episode]()
    }
    
    fileprivate
    func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int?
    {
        return podcasts.index(of: podcast)
    }
}
