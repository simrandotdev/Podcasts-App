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
    
    
    
    func downloadEpisode(episode: Episode)
    {
        var episodes = downloadedEpisodes()
        if doesEpisodeExist(episode: episode) {
            return
        }
        episodes.insert(episode, at: 0)
        saveEpisodes(episodes)
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
    
    func deleteEpisode(at index: Int)
    {
        var episodes = downloadedEpisodes()
        episodes.remove(at: index)
        saveEpisodes(episodes)
        
    }
    
    fileprivate
    func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int?
    {
        return podcasts.index(of: podcast)
    }
    
    fileprivate
    func saveEpisodes(_ episodes: [Episode])
    {
        do
        {
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: downloadedEpisodeKey)
        }
        catch let encodeErr
        {
            print("Failed to encode episode: ", encodeErr)
        }
    }
    
    fileprivate
    func doesEpisodeExist(episode: Episode) -> Bool
    {
        let episodes = downloadedEpisodes()
        for ep in episodes {
            if( ep.author == episode.author &&
                ep.content == episode.content &&
                ep.description == episode.description &&
                ep.imageUrl == episode.imageUrl &&
                ep.title == episode.title &&
                ep.pubDate == episode.pubDate)
            {
                return true
            }
        }
        
        return false
    }
}
