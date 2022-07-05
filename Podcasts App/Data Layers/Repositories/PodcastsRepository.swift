//
//  PodcastsRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation

class PodcastsRepository {
    
    private let api = APIService.shared
    
    public func fetchAll() async throws -> [Podcast] {
        let podcasts = try await api.fetchPodcastsAsync(searchText: "podcasts")
        return podcasts
    }
}
