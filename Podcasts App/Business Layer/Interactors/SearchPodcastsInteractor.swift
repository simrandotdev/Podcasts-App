//
//  SearchPodcastsInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver


// MARK: - SearchPodcastInteractable protocol

protocol SearchPodcastsInteractable {
    
    var podcasts: [Podcast] { get set }
    
    func fetchPodcasts() async throws
}


// MARK: - SearchPodcastInteractable Implementation


class SearchPodcastsInteractor {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var podcastRepository: PodcastsRepository
    
    
    // MARK: - Published properties
    
    
    @Published var podcasts: [Podcast] = []
    
    
    // MARK: Public methods
    
    
    func fetchPodcasts() async throws {
        podcasts = try await podcastRepository.fetchAll()
    }
    
    func searchPodcasts(forValue value: String) async throws {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try await fetchPodcasts()
        } else {
            podcasts = try await podcastRepository.search(forValue: value)
        }
    }
}
