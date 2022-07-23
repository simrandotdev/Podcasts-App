//
//  EpisodesInteractor.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine

// MARK: - EpisodesInteractable protocol

protocol EpisodesInteractable {
    
    var episodes: CurrentValueSubject<[Episode], Never> { get set }
    var recentlyPlayedEpisodes: CurrentValueSubject<[Episode], Never> { get set }
    
    func fetchEpisodes(forPodcast podcast: Podcast) async throws
    func searchEpisodes(forValue value: String) async throws
    func saveInHistory(episode: Episode)  async throws
    func fetchEpisodesFromHistory() async throws
}


// MARK: - EpisodesInteractable Implementation


class EpisodesInteractor: EpisodesInteractable {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var episodesRepository: EpisodesRepository
    
    
    // MARK: - Published properties
    
    
    @Published var episodes: CurrentValueSubject<[Episode], Never> = CurrentValueSubject([])
    @Published var recentlyPlayedEpisodes: CurrentValueSubject<[Episode], Never> = CurrentValueSubject([])
    
    private var originalEpisodes: [Episode] = []
    
    
    // MARK: Public methods
    
    
    func fetchEpisodes(forPodcast podcast: Podcast) async throws {
        
        originalEpisodes = try await episodesRepository.fetchAllEpisodes(forPodcast: podcast)
        episodes.send(originalEpisodes)
    }
    
    
    func searchEpisodes(forValue value: String) async throws {
        
    }
    
    
    func saveInHistory(episode: Episode)  async throws {
        
        try await episodesRepository.saveInHistory(episode: episode)
    }
    
    
    func fetchEpisodesFromHistory() async throws {
        
        let fetchedEpisodesFromHistory = try await episodesRepository.getEpisodesFromHistory()
        recentlyPlayedEpisodes.send(fetchedEpisodesFromHistory)
    }
}
