//
//  PodcastsInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine


// MARK: - PodcastsInteractable protocol

protocol PodcastsInteractable {
    
    func fetchPodcasts() async throws -> [Podcast]
    func searchPodcasts(forValue value: String) async throws  -> [Podcast]
    func favorite(podcast: Podcast) async throws  -> [Podcast]
    func unfavorite(podcast: Podcast) async throws  -> [Podcast]
    func isFavorite(podcast: Podcast) async throws -> Bool
    func fetchFavorites() async throws -> [Podcast]
}


// MARK: - SearchPodcastInteractable Implementation


class PodcastsInteractor: PodcastsInteractable {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var podcastRepository: PodcastsRepository
    
    
    
    private var originalPodcasts: [Podcast] = []
    
    
    // MARK: Public methods
    
    
    func fetchPodcasts() async throws  -> [Podcast] {
        
        return originalPodcasts.isEmpty ? try await podcastRepository.fetchAll() : originalPodcasts
    }
    
    
    func searchPodcasts(forValue value: String) async throws -> [Podcast] {
        
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try await fetchPodcasts()
        } else {
            return try await podcastRepository.search(forValue: value)
        }
    }
    
    
    func favorite(podcast: Podcast) async throws -> [Podcast] {
        
        try await podcastRepository.favorite(podcast: podcast)
        return try await fetchPodcasts()
    }
    
    
    func unfavorite(podcast: Podcast) async throws -> [Podcast] {
        
        try await podcastRepository.unfavorite(podcast: podcast)
        return try await fetchPodcasts()
    }
    
    
    func isFavorite(podcast: Podcast) async throws -> Bool {
        
        return try await podcastRepository.isFavorite(podcast: podcast)
    }
    
    
    func fetchFavorites() async throws -> [Podcast] {
        
        return try await podcastRepository.fetchFavoritePodcasts()
    }
}
