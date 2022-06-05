//
//  HistoryViewModel.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver

class HistoryViewModel: ObservableObject {
    
    @Injected var persistanceManager: PodcastsPersistantManager
    
    @Published var episodes: [EpisodeViewModel] = []
    
    func loadRecentlyPlayedEpisodes() {
        let x = persistanceManager.fetchAllRecentlyPlayedPodcasts()
        episodes = x?.map{ EpisodeViewModel(episode: $0)} ?? [EpisodeViewModel]()
    }
}
