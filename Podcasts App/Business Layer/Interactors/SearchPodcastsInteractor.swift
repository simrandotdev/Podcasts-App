//
//  SearchPodcastsInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver

class SearchPodcastsInteractor {
    
    // MARK: - Dependencies
    @Injected private var podcastRepository: PodcastsRepository
    
    // MARK: - Published properties
    @Published var podcasts: [Podcast] = []
    
    func fetchPodcasts() async throws {
        podcasts = try await podcastRepository.fetchAll()
    }
}
