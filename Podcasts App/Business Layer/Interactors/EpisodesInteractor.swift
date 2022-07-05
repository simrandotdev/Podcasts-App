//
//  EpisodesInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver


// MARK: - EpisodesInteractable protocol

protocol EpisodesInteractable {
    
    var episodes: [Episode] { get set }
    
    
    func fetchEpisodes(forPodcast podcast: Podcast) async throws
    func searchEpisodes(forValue value: String) async throws
}


// MARK: - EpisodesInteractable Implementation


class EpisodesInteractor: EpisodesInteractable {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var episodesRepository: EpisodesRepository
    
    
    // MARK: - Published properties
    
    
    @Published var episodes: [Episode] = []
    private var originalEpisodes: [Episode] = []
    
    
    // MARK: Public methods
    
    
    func fetchEpisodes(forPodcast podcast: Podcast) async throws {
        
        originalEpisodes = try await episodesRepository.fetchAllEpisodes(forPodcast: podcast)
        episodes = originalEpisodes
    }
    
    
    func searchEpisodes(forValue value: String) async throws {
        
    }
}
