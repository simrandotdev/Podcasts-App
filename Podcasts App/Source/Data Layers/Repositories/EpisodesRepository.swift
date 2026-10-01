//
//  EpisodesRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver

// MARK: - EpisodesRepositoryProtocol


protocol EpisodesRepositoryProtocol {
    
    func fetchAllEpisodes(forPodcast podcast: Podcast) async throws -> [Episode]
}


// MARK: - EpisodesRepositoryProtocol Implementation


class EpisodesRepository {
    
    
    // MARK: - Dependencies
    
    
    @Injected var api: APIService
    @Injected var db: PersistanceManager
    
    // MARK: - Public properties
    
    
    public func fetchAllEpisodes(forPodcast podcast: Podcast) async throws -> [Episode] {
        
        guard let rssFeedUrl = podcast.rssFeedUrl else { return [] }
        
        let episodes = try await api.fetchEpisodesAsync(forPodcast: rssFeedUrl)
        return episodes
    }
    
    public func saveInHistory(episode: Episode) async throws {
        
        try await db.dbQueue?.write({ db in
            // Re-insert so a replayed episode moves to the end of the table (newest in history).
            _ = try episode.delete(db)
            try episode.insert(db)
        })
    }
    
    public func getEpisodesFromHistory() async throws -> [Episode] {
        
        return try await db.dbQueue?.read({ db in
            return try Episode.fetchAll(db).reversed()
        }) ?? []
    }
}
