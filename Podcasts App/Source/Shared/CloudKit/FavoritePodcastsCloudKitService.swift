//
//  FavoritePodcastsService.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-02-06.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import BaadalKit
import CloudKit

class FavoritePodcastsCloudKitService {
    
    @Injected private var localPersistantManager: PodcastsPersistantManager
    @Injected private var bkManager: BaadalManager
    
    func fetchFavoritePodcasts() async throws -> [Podcast] {

        return try await bkManager.fetch(recordType: Constants.BKConstants.recordTypeFavoritePodcasts)
            .compactMap({ record in
                guard let author = record.object(forKey: "author") as? String,
                      let title = record.object(forKey: "title") as? String,
                      let image = record.object(forKey: "image") as? String,
                      let totalEpisodes = record.object(forKey: "totalEpisodes") as? Int,
                      let rssFeedUrl = record.object(forKey: "rssFeedUrl") as? String else {
                          return nil
                      }
                
                let podcast = Podcast(recordId: record.recordID.recordName,
                                      title: title,
                                      author: author,
                                      image: image,
                                      totalEpisodes: totalEpisodes,
                                      rssFeedUrl: rssFeedUrl)
                info("\(podcast.title ?? "") fetched")
                return podcast
            })
    }

    func favoritePodcast(_ podcast: Podcast) async throws {
        
        let podcasts = try await fetchFavoritePodcasts()
        
        if podcasts.contains(podcast) {
            return
        }
        
        let favoritePodcastRecord = CKRecord(recordType: Constants.BKConstants.recordTypeFavoritePodcasts)
        favoritePodcastRecord.setValue(podcast.author, forKey: "author")
        favoritePodcastRecord.setValue(podcast.title, forKey: "title")
        favoritePodcastRecord.setValue(podcast.image, forKey: "image")
        favoritePodcastRecord.setValue(podcast.totalEpisodes, forKey: "totalEpisodes")
        favoritePodcastRecord.setValue(podcast.rssFeedUrl, forKey: "rssFeedUrl")

        _ = try await bkManager.save(record: favoritePodcastRecord)
    }

    func unfavoritePodcast(_ podcast: Podcast) async throws {
        
        let podcasts = try await fetchFavoritePodcasts()
        let podcastToUnfavorite = podcasts.first { $0 == podcast }
        guard let unfavorite = podcastToUnfavorite else { return }
        _ = try await bkManager.delete(BKFavoritePodcast(podcast: unfavorite))
    }
    
    func unfavoriteAll() async throws {
        let podcasts = try await fetchFavoritePodcasts()
        for podcast in podcasts {
            try await unfavoritePodcast(podcast)
        }
    }

    func isFavorite(_ podcast: Podcast) async throws -> Bool {
        
        let podcasts = try await fetchFavoritePodcasts()
        return podcasts.contains(podcast)
    }
    
    func syncLocalToCloud() async throws {
        
        let localPodcasts = localPersistantManager.fetchFavoritePodcasts()
        let cloudPodcasts = try await fetchFavoritePodcasts()
        
        let bkManager = BaadalManager(identifier: "iCloud.app.simran.PodcastsApp")
        
        // Sync LOCAL TO CLOUD
        for localPodcast in localPodcasts {
            
            // If Cloud does not have the current local pocast, skip to next local podcast
            if cloudPodcasts.contains(localPodcast) { continue }
            
            let favoritePodcastRecord = CKRecord(recordType: "FavoritePodcasts") // TODO: Extract into some place common
            favoritePodcastRecord.setValue(localPodcast.author, forKey: "author")
            favoritePodcastRecord.setValue(localPodcast.title, forKey: "title")
            favoritePodcastRecord.setValue(localPodcast.image, forKey: "image")
            favoritePodcastRecord.setValue(localPodcast.totalEpisodes, forKey: "totalEpisodes")
            favoritePodcastRecord.setValue(localPodcast.rssFeedUrl, forKey: "rssFeedUrl")
            
            do {
                _ = try await bkManager.save(record: favoritePodcastRecord)
            } catch {
                print("❌ Error syncing favorite podcasts with error: \(error)")
            }
            
        }
    }
    
    func syncCloudToLocal() async throws {
        let cloudPodcasts = try await fetchFavoritePodcasts()
        
        for cloudPodcast in cloudPodcasts {
            localPersistantManager.removeAllFavoritePodcasts()
            _ = localPersistantManager.favoritePodcast(podcast: cloudPodcast)
        }
    }
}
