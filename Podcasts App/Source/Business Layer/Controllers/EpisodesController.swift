//
//  EpisodesController.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine


// MARK: - EpisodesControllable protocol


protocol EpisodesControllable {
    
    var episodes: [EpisodeViewModel] { get set }
    
    func fetchEpisodes(forPodcast podcast: PodcastViewModel) async
    func saveInHistory(episode: Episode)  async
    func fetchEpisodesFromHistory() async
}


// MARK: - EpisodesControllable implementation


class EpisodesController: EpisodesControllable, ObservableObject {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var interactor: EpisodesInteractor
    
    
    // MARK: - Publisher Properties
    
    
    @Published var episodes: [EpisodeViewModel] = []
    @Published var recentlyPlayedEpisodes: [EpisodeViewModel] = []
    @Published var isLoading: Bool = false
    
    
    // MARK: - Private properties
    
    
    private var cancellable = Set<AnyCancellable>()
    
    
    
    // MARK: - Initializer and setups
    
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        
        interactor
            .episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                self?.episodes = episodes.map { EpisodeViewModel(episode: $0) }
            }
            .store(in: &cancellable)
        
        interactor
            .recentlyPlayedEpisodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                self?.recentlyPlayedEpisodes = episodes.map { EpisodeViewModel(episode: $0) }
            }
            .store(in: &cancellable)
        
    }
    
    
    
    // MARK: - EpisodesControllable protocol implementation
    
    
    @MainActor func fetchEpisodes(forPodcast podcast: PodcastViewModel) async {
        
        isLoading = true
        do {
            let podcastModel = Podcast(podcastViewModel: podcast)
            try await interactor.fetchEpisodes(forPodcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
    }
    
    
    @MainActor func saveInHistory(episode: Episode)  async {
        
        do {
            try await interactor.saveInHistory(episode: episode)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        
    }
    
    
    @MainActor func fetchEpisodesFromHistory() async {
        
        do {
            try await interactor.fetchEpisodesFromHistory()
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        
    }
}
