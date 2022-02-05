//
//  FavoritePodcastsViewModel.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-02-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Combine
import Resolver

class FavoritePodcastsViewModel {
    
    @Published var favoritePodcasts : [Podcast] = [Podcast]()
    
    @Injected fileprivate var favoritePodcastRepository: PodcastsPersistantManager
    
    init() {
        fetchPodcasts()
    }
    
    func fetchPodcasts() {
        favoritePodcasts = favoritePodcastRepository.fetchFavoritePodcasts()
    }
    
    func favoritePodcast(_ podcast: Podcast) {
        favoritePodcasts = favoritePodcastRepository.favoritePodcast(podcast: podcast)
    }
    
    func unfavoritePodcast(_ podcast: Podcast) {
        favoritePodcasts = favoritePodcastRepository.unfavoritePodcast(podcast: podcast)
    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        return favoritePodcastRepository.isFavorite(podcast: podcast)
    }
}
