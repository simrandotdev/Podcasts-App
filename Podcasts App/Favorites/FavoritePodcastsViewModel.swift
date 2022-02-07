//
//  FavoritePodcastsViewModel.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-02-06.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Combine
import Resolver

class FavoritePodcastsViewModel {
    
    @Published var favoritePodcasts : [Podcast] = []
    @Published var isFavorite: Bool = false
    
    @Injected private var favoritePodcastLocalService: PodcastsPersistantManager
    @Injected private var favoritePodcastCloudService: FavoritePodcastsService
    
    fileprivate var cancellable = Set<AnyCancellable>()
    
    init() {
        Task {
            try await fetchFavoritePodcasts()
        }
    }
    
    func fetchFavoritePodcasts() async throws {
        let fPodcasts = try await favoritePodcastCloudService.fetchFavoritePodcasts()
        info("Favorite Podcasts fetched -> \(fPodcasts.count)")
        favoritePodcasts = fPodcasts
        
    }

    func favoritePodcast(_ podcastViewModel: PodcastViewModel) async throws {

        favoritePodcasts = try await favoritePodcastCloudService.fetchFavoritePodcasts()
        
        info("Favorite Podcasts --> \(favoritePodcasts.count)")
        
        guard let podcast = favoritePodcasts.first(where: { favoritePodcast in
            return favoritePodcast == Podcast(podcastViewModel: podcastViewModel)
        }) else {
            try await favoritePodcastCloudService.favoritePodcast(Podcast(podcastViewModel: podcastViewModel))
            return
        }
        
        info("Podcast to favorite --> \(podcast.title) : \(podcast.recordId)")
    }

    func unfavoritePodcast(_ podcastViewModel: PodcastViewModel) async throws {

        favoritePodcasts = try await favoritePodcastCloudService.fetchFavoritePodcasts()
        
        info("Unfavorite Podcasts --> \(favoritePodcasts.count)")
        
        guard let podcast = favoritePodcasts.first(where: { favoritePodcast in
            return favoritePodcast == Podcast(podcastViewModel: podcastViewModel)
        }) else { return }
        
        info("Podcast to unfavorite --> \(podcast.title) : \(podcast.recordId)")
        
        try await favoritePodcastCloudService.unfavoritePodcast(podcast)
    }

    func isFavorite(_ podcastViewModel: PodcastViewModel) async throws -> Bool {
        
        let podcastModel = Podcast(podcastViewModel: podcastViewModel)
        try await fetchFavoritePodcasts()
        isFavorite = try await favoritePodcastCloudService.isFavorite(podcastModel)
        return isFavorite
    }
    
}
