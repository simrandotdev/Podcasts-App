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

class FavoritePodcastsService {
    
    @Injected private var favoritePodcastRepository: PodcastsPersistantManager
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
                info("\(podcast.title) fetched")
                return podcast
            })
    }

    func favoritePodcast(_ podcast: Podcast) async throws {

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
        let podcastToUnfavorite = podcasts.first { $0.recordId == podcast.recordId }
        guard let unfavorite = podcastToUnfavorite else { return }
        _ = try await bkManager.delete(BKFavoritePodcast(podcast: unfavorite))
    }

    func isFavorite(_ podcast: Podcast) async throws -> Bool {
        let podcasts = try await fetchFavoritePodcasts()
        return podcasts.contains(podcast)
    }
}
