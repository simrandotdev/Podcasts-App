import Foundation
import Resolver

class PodcastsPersistantManager {
    fileprivate let favoritePodcastsKey = "favoritePodcasts"
    fileprivate let downloadedEpisodeKey = "downloadedEpisodeKey"
    fileprivate let recentlyPlayedPodcastsKey = "recentlyPlayedPodcasts"
    
    @Injected private var localStorageManager: LocalStorageManager
}

// MARK:- Favorite Podcasts
extension PodcastsPersistantManager {
    
    func favoritePodcast(podcast: Podcast) -> [Podcast]? {
        var favoritePodcasts = fetchFavoritePodcasts()
        do {
            if favoritePodcasts.contains(where: { podcast == $0 }) { return nil }
            favoritePodcasts.append(podcast)
            try localStorageManager.save(favoritePodcasts, forKey: favoritePodcastsKey)
        } catch {
            print("Failed to save Podcasts: \(error)")
        }
        return favoritePodcasts
    }
    
    func unfavoritePodcast(podcast: Podcast) -> [Podcast] {
        var favoritePodcasts = fetchFavoritePodcasts()
        do {
            let indexToDelete = indexOfPodcastToDelete(podcast: podcast, from: favoritePodcasts)
            if let indexToDelete = indexToDelete,
                indexToDelete >= 0 {
                favoritePodcasts.remove(at: indexToDelete)
            }
            
            try localStorageManager.save(favoritePodcasts, forKey: favoritePodcastsKey)
        } catch {
            print("Failed to save Podcasts: \(error)")
        }
        return favoritePodcasts
    }
    
    func fetchFavoritePodcasts() -> [Podcast] {
        var favoritePodcasts = [Podcast]()
        do {
            favoritePodcasts = try localStorageManager.load(fromKey: favoritePodcastsKey)
        } catch  {
            print("Failed to fetch Podcasts: \(error)")
        }
        return favoritePodcasts
    }
    
    func isFavorite(podcast: Podcast) -> Bool {
        let podcasts = fetchFavoritePodcasts()
        return podcasts.contains(podcast)
    }
    
    // MARK: Helper methods
    fileprivate func indexOfPodcastToDelete(podcast: Podcast, from podcasts: [Podcast]) -> Int? {
        return podcasts.firstIndex(of: podcast)
    }
}

// MARK:- Download Podcasts
extension PodcastsPersistantManager {
    func downloadEpisode(episode: Episode) {
        var episodes = downloadedEpisodes()
        if doesEpisodeExist(episode: episode) {
            return
        }
        episodes.insert(episode, at: 0)
        saveEpisodes(episodes)
    }
    
    func downloadedEpisodes() -> [Episode] {
        do {
            return try localStorageManager.load(fromKey: downloadedEpisodeKey)
        }
        catch let decodeErr {
            print("Error Decoding Episodes: ", decodeErr)
        }
        return []
    }
    
    func deleteEpisode(at index: Int) {
        var episodes = downloadedEpisodes()
        episodes.remove(at: index)
        saveEpisodes(episodes)
    }
    
    // MARK: Helper methods
    fileprivate func saveEpisodes(_ episodes: [Episode]) {
        do {
            try localStorageManager.save(episodes, forKey: downloadedEpisodeKey)
        } catch let encodeErr {
            print("Failed to encode episode: ", encodeErr)
        }
    }
    
    fileprivate func doesEpisodeExist(episode: Episode) -> Bool {
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
extension PodcastsPersistantManager {
    func addRecentlyPlayedPodcast(episode: Episode) {
        guard var recentlyPlayedPosts = fetchAllRecentlyPlayedPodcasts() else { return }
        
        if let indexToRemove = recentlyPlayedPosts.firstIndex(where: { (ep) -> Bool in
            episode.title == ep.title
            && episode.author == ep.author
            && episode.pubDate == ep.pubDate}) {
            
            recentlyPlayedPosts.remove(at: indexToRemove)
        }
        
        recentlyPlayedPosts.insert(episode, at: 0)
        
        do {
            try localStorageManager.save(recentlyPlayedPosts, forKey: recentlyPlayedPodcastsKey)
        } catch {
            print("Failed to save recently played Podcast")
        }
    }
    
    func fetchRecent100PlayedPodcasts() -> [Episode]? {
        let episodes = fetchAllRecentlyPlayedPodcasts()
        if episodes?.count ?? 0 <= 100 { return episodes }
        
        guard let newEpisodes = episodes?.prefix(upTo: 101) else { return [Episode]() }
        return Array(newEpisodes)
    }
    
    func fetchAllRecentlyPlayedPodcasts() -> [Episode]? {
        do {
            return try localStorageManager.load(fromKey: recentlyPlayedPodcastsKey)
        } catch  {
            print("Failed to Convert Recently played JSON String to Array of Episodes")
        }
        return [Episode]()
    }
}
