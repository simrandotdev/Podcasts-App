//
//  PodcastsRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import GRDB

// MARK: - PodcastsRepositoryProtocol


protocol PodcastsRepositoryProtocol {
    
    func fetchAll() async throws -> [Podcast]
    func search(forValue value: String) async throws -> [Podcast]
    func favorite(podcast: Podcast) async throws
    func unfavorite(podcast: Podcast) async throws
    func isFavorite(podcast: Podcast) async throws -> Bool
    func fetchFavoritePodcasts() async throws -> [Podcast]
}


// MARK: - PodcastsRepositoryProtocol Implementation


class PodcastsRepository: PodcastsRepositoryProtocol {
    
    
    // MARK: - Dependencies
    
    
    @Injected var api: APIService
    @Injected var db: PersistanceManager
    
    
    // MARK: - Public properties
    
    
    public func fetchAll() async throws -> [Podcast] {
        let podcasts = try await search(forValue: "podcasts")
        return podcasts
    }
    
    
    public func search(forValue value: String) async throws -> [Podcast] {
        let podcasts = try await api.fetchPodcastsAsync(searchText: value)
        return podcasts
    }
    
    
    public func favorite(podcast: Podcast) async throws {
        
        try await db.dbQueue?.write({ db in
            try podcast.save(db)
        })
    }
    
    
    public func unfavorite(podcast: Podcast) async throws {
        _ = try await db.dbQueue?.write({ db in
            try podcast.delete(db)
        })
    }
    
    
    public func isFavorite(podcast: Podcast) async throws -> Bool {
        let favoritePodcast = try await db.dbQueue?.read({ db in
            return try Podcast
                .filter(Column("rssFeedUrl") == podcast.rssFeedUrl)
                .fetchOne(db)
        })
        
        return favoritePodcast != nil
    }
    
    public func fetchFavoritePodcasts() async throws -> [Podcast] {
        let favoritePodcasts = try await db.dbQueue?.read({ db in
            return try Podcast
                .fetchAll(db)
        })
        
        return favoritePodcasts ?? []
        
    }
}
