//
//  HistoryViewModel.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine

class HistoryViewModel: ObservableObject {
    
    @Injected var persistanceManager: PodcastsPersistantManager
    
    @Published var episodes: [EpisodeViewModel] = []
    @Published var searchText = ""
    
    private var allEpisodes: [EpisodeViewModel] = []
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        $searchText
            .sink { [weak self] text in
                guard let self = self else { return }
                
                if text.isEmpty {
                    self.episodes = self.allEpisodes
                    return
                }
                self.episodes = self.allEpisodes.compactMap { episode in
                    return episode.title.localizedCaseInsensitiveContains(text) ? episode : nil
                }
            }
            .store(in: &cancellable)
    }
    
    func loadRecentlyPlayedEpisodes() {
        let x = persistanceManager.fetchAllRecentlyPlayedPodcasts()
        episodes = x?.map{ EpisodeViewModel(episode: $0)} ?? [EpisodeViewModel]()
        allEpisodes = episodes
    }
}
