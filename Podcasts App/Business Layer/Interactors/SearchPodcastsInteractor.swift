//
//  PodcastsInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver


// MARK: - PodcastsInteractable protocol

protocol PodcastsInteractable {
    
    var podcasts: [Podcast] { get set }
    
    
    func fetchPodcasts() async throws
    func searchPodcasts(forValue value: String) async throws
}


// MARK: - SearchPodcastInteractable Implementation


class PodcastsInteractor {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var podcastRepository: PodcastsRepository
    
    
    // MARK: - Published properties
    
    
    @Published var podcasts: [Podcast] = []
    private var originalPodcasts: [Podcast] = []
    
    
    // MARK: Public methods
    
    
    func fetchPodcasts() async throws {
        
        originalPodcasts = originalPodcasts.isEmpty ? try await podcastRepository.fetchAll() : originalPodcasts
        podcasts = originalPodcasts
    }
    
    func searchPodcasts(forValue value: String) async throws {
        
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try await fetchPodcasts()
        } else {
            podcasts = try await podcastRepository.search(forValue: value)
        }
    }
}
