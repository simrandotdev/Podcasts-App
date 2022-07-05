//
//  PodcastsRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver

// MARK: - PodcastsRepositoryProtocol


protocol PodcastsRepositoryProtocol {
    
    func fetchAll() async throws -> [Podcast]
    func search(forValue value: String) async throws -> [Podcast]
}


// MARK: - PodcastsRepositoryProtocol Implementation


class PodcastsRepository {
    
    
    // MARK: - Dependencies
    
    
    @Injected var api: APIService
    
    
    // MARK: - Public properties
    
    
    public func fetchAll() async throws -> [Podcast] {
        let podcasts = try await search(forValue: "podcasts")
        return podcasts
    }
    
    
    public func search(forValue value: String) async throws -> [Podcast] {
        let podcasts = try await api.fetchPodcastsAsync(searchText: value)
        return podcasts
    }
}
