import Foundation

class PodcastsRepository {
    fileprivate let favoriteEpisodeKey = "favoritePodcasts"
    fileprivate let downloadedEpisodeKey = "downloadedEpisodeKey"
    fileprivate let recentlyPlayedPodcastsKey = "recentlyPlayedPodcasts"
}

// MARK:- Favorite Podcasts
extension PodcastsRepository {
    func favoritePodcast(podcast: Podcast) -> [Podcast]? {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return nil }
        do {
            if favoritePodcasts.contains(where: { podcast == $0 }) { return nil }
            favoritePodcasts.append(podcast)
            let favoritePostcastsData = try NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts, requiringSecureCoding: false)
            UserDefaults.standard.setValue(favoritePostcastsData, forKey: favoriteEpisodeKey)
            
        } catch {
            print("Failed to save Podcasts.")
        }
        return favoritePodcasts
    }
    
    func unfavoritePodcast(podcast: Podcast) -> [Podcast]? {
        guard var favoritePodcasts = fetchFavoritePodcasts() else { return nil }
        do {
            let indexToDelete = indexOfPodcastToDelete(podcast: podcast, from: favoritePodcasts)
            if let indexToDelete = indexToDelete,
                indexToDelete >= 0 {
                favoritePodcasts.remove(at: indexToDelete)
            }
            let favoritePostcastsData = try NSKeyedArchiver.archivedData(withRootObject: favoritePodcasts, requiringSecureCoding: false)
            UserDefaults.standard.setValue(favoritePostcastsData, forKey: favoriteEpisodeKey)
        } catch {
            print("Failed to save Podcasts.")
        }
        return favoritePodcasts
    }
    
    func fetchFavoritePodcasts() -> [Podcast]? {
        let podcastsData = UserDefaults.standard.data(forKey: favoriteEpisodeKey)
        let favoritePodcasts = NSKeyedUnarchiver.unarchiveObject(with: podcastsData ?? Data()) as? [Podcast] ?? [Podcast]()
        return favoritePodcasts
    }
    
    func isFavorite(podcast: Podcast) -> Bool {
        let podcasts = fetchFavoritePodcasts()
        return podcasts?.contains(podcast) ?? false
    }
    
    // MARK: Helper methods
    fileprivate func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int? {
        return podcasts.firstIndex(of: podcast)
    }
}

// MARK:- Download Podcasts
extension PodcastsRepository {
    func downloadEpisode(episode: Episode) {
        var episodes = downloadedEpisodes()
        if doesEpisodeExist(episode: episode) {
            return
        }
        episodes.insert(episode, at: 0)
        saveEpisodes(episodes)
    }
    
    func downloadedEpisodes() -> [Episode] {
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
    
    // MARK: Helper methods
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

// MARK:- Recently Played Podcast Episodes
extension PodcastsRepository
{
    func addRecentlyPlayedPodcast(episode: Episode)
    {
        guard var recentlyPlayedPosts = fetchAllRecentlyPlayedPodcasts() else { return }
        
        if let indexToRemove = recentlyPlayedPosts.firstIndex(where: { (ep) -> Bool in
            episode.title == ep.title
            && episode.author == ep.author
            && episode.pubDate == ep.pubDate}) {
            
            recentlyPlayedPosts.remove(at: indexToRemove)
        }
        
        recentlyPlayedPosts.insert(episode, at: 0)
        
        do {
            let recentlyPlayedPodcastsJSONString = try recentlyPlayedPosts.toJSONString()
            UserDefaults.standard.set(recentlyPlayedPodcastsJSONString, forKey: recentlyPlayedPodcastsKey)
        } catch {
            print("Failed to save recently played Podcast")
        }
    }
    
    func fetchRecent100PlayedPodcasts() -> [Episode]?
    {
        let episodes = fetchAllRecentlyPlayedPodcasts()
        if episodes?.count ?? 0 <= 100 { return episodes }
        
        guard let newEpisodes = episodes?.prefix(upTo: 101) else { return [Episode]() }
        return Array(newEpisodes)
    }
    
    func fetchAllRecentlyPlayedPodcasts() -> [Episode]?
    {
        guard let recentlyPlayedPodcastJSONString
            = UserDefaults.standard.string(forKey: recentlyPlayedPodcastsKey) else { return [Episode]() }
        do {
            let recentPodcasts = try recentlyPlayedPodcastJSONString.fromJsonString(to: [Episode].self)
            return recentPodcasts
        } catch  {
            print("Failed to Convert Recently played JSON String to Array of Episodes")
        }
        return [Episode]()
    }
}
