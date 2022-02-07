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
    
    @Published var favoritePodcasts : [PodcastViewModel] = []
    @Published var isFavorite: Bool = false
    
    @Injected private var favoritePodcastLocalService: PodcastsPersistantManager
    @Injected private var favoritePodcastCloudService: FavoritePodcastsService
    
    #if DEBUG
    private var isSubscribedUser = true
    #endif
    
    fileprivate var cancellable = Set<AnyCancellable>()
    
    init() {
        Task {
            try await fetchFavoritePodcasts()
        }
    }
    
    
    
    // MARK: - fetchFavoritePodcasts
    func fetchFavoritePodcasts() async throws {
        
        if isSubscribedUser {

            do {
                favoritePodcasts = try await fetchCloudPodcasts().sorted(by: { return $0.title < $1.title })
            } catch {
                favoritePodcasts = fetchLocalPodcasts().sorted(by: { return $0.title < $1.title })
                throw error
            }
        } else {
            favoritePodcasts = fetchLocalPodcasts().sorted(by: { return $0.title < $1.title })
        }
    }
    
    private func fetchLocalPodcasts() -> [PodcastViewModel] {
        return favoritePodcastLocalService
            .fetchFavoritePodcasts()
            .map({ PodcastViewModel(podcast: $0) })
    }
    
    private func fetchCloudPodcasts() async throws -> [PodcastViewModel] {
        return try await favoritePodcastCloudService
            .fetchFavoritePodcasts()
            .map({ PodcastViewModel(podcast: $0) })
    }

    
    
    // MARK: - favoritePodcast
    func favoritePodcast(_ podcastViewModel: PodcastViewModel) async throws {

        favoritePodcasts = favoritePodcastLocally(podcastViewModel).sorted(by: { return $0.title < $1.title })
        
        if isSubscribedUser {
            
            let favoritePodcasts = try await fetchCloudPodcasts().sorted(by: { return $0.title < $1.title })
            
            let existingPodcast = favoritePodcasts.first(where: { favoritePodcast in
                return favoritePodcast.rssFeedUrl == podcastViewModel.rssFeedUrl
            })
            
            if existingPodcast == nil {
                try await favoritePodcastInCloud(podcastViewModel)
            }
        }
    }
    
    private func favoritePodcastLocally(_ podcastViewModel: PodcastViewModel) -> [PodcastViewModel] {
        return favoritePodcastLocalService
            .favoritePodcast(podcast: Podcast(podcastViewModel: podcastViewModel))
            .map({ PodcastViewModel(podcast: $0) })
    }
    
    private func favoritePodcastInCloud(_ podcastViewModel: PodcastViewModel) async throws {
        try await favoritePodcastCloudService.favoritePodcast(Podcast(podcastViewModel: podcastViewModel))
    }
    
    
    
    // MARK: - unfavoritePodcast
    func unfavoritePodcast(_ podcastViewModel: PodcastViewModel) async throws {
        
        favoritePodcasts = unfavoritePodcastLocally(podcastViewModel).sorted(by: { return $0.title < $1.title })
        
        
        if isSubscribedUser {
            
            try await unfavoritePodcastInCloud(podcastViewModel)
        }
    }
    
    private func unfavoritePodcastLocally(_ podcastViewModel: PodcastViewModel) -> [PodcastViewModel] {
        return favoritePodcastLocalService
            .unfavoritePodcast(podcast: Podcast(podcastViewModel: podcastViewModel))
            .map({ PodcastViewModel(podcast: $0) })
    }
    
    private func unfavoritePodcastInCloud(_ podcastViewModel: PodcastViewModel) async throws {
        try await favoritePodcastCloudService.unfavoritePodcast(Podcast(podcastViewModel: podcastViewModel))
    }

    
    
    // MARK: - isFavorite
    func isFavorite(_ podcastViewModel: PodcastViewModel) async throws -> Bool {
        
        try await fetchFavoritePodcasts()

        return favoritePodcasts.contains { vm in
            return vm.rssFeedUrl == podcastViewModel.rssFeedUrl
        }
    }

}
