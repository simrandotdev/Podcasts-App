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
    func favorite(podcast: Podcast) async throws
    func unfavorite(podcast: Podcast) async throws
    func isFavorite(podcast: Podcast) async throws -> Bool
}


// MARK: - SearchPodcastInteractable Implementation


class PodcastsInteractor: PodcastsInteractable {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var podcastRepository: PodcastsRepository
    
    
    // MARK: - Published properties
    
    
    @Published var podcasts: [Podcast] = []
    @Published var favoritePodcasts: [Podcast] = []
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
    
    
    func favorite(podcast: Podcast) async throws {
        
        try await podcastRepository.favorite(podcast: podcast)
        try await fetchPodcasts()
    }
    
    
    func unfavorite(podcast: Podcast) async throws {
        
        try await podcastRepository.unfavorite(podcast: podcast)
        try await fetchPodcasts()
    }
    
    
    func isFavorite(podcast: Podcast) async throws -> Bool {
        
        return try await podcastRepository.isFavorite(podcast: podcast)
    }
    
    func fetchFavorites() async throws {
        
        favoritePodcasts = try await podcastRepository.fetchFavoritePodcasts()
    }
}
