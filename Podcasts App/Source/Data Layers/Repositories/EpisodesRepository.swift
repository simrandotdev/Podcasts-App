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
    
    
    // MARK: - Public properties
    
    
    public func fetchAllEpisodes(forPodcast podcast: Podcast) async throws -> [Episode] {
        
        guard let rssFeedUrl = podcast.rssFeedUrl else { return [] }
        
        let episodes = try await api.fetchEpisodesAsync(forPodcast: rssFeedUrl)
        return episodes
    }
}
