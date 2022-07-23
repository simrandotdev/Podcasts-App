//
//  PodcastsController.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine


// MARK: - PodcastControllable implementation


class PodcastsController: ObservableObject {
    
    
    // MARK: - Dependencies
    
    
    @Injected var podcastsInteractor: PodcastsInteractable
    @Injected var episodesInteractor: EpisodesInteractable
    
    
    init(podcastsInteractor: PodcastsInteractable, episodesInteractor: EpisodesInteractable) {
        
        self.podcastsInteractor = podcastsInteractor
        self.episodesInteractor = episodesInteractor
    }
    
    
    // MARK: - Publisher Properties
    
    
    @Published var podcasts: [PodcastViewModel] = []
    @Published var favoritePodcasts: [PodcastViewModel] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    
    
    // MARK: - Private properties
    
    
    private var cancellable = Set<AnyCancellable>()
    
    
    
    // MARK: - Initializer and setups
    
    
    init() {
        setupSubscriptions()
        setupSearchText()
    }
    
    
    // MARK: - PodcastControllable protocol implementation
    
    
    @MainActor func fetchPodcasts() async {
        isLoading = true
        do {
            try await podcastsInteractor.fetchPodcasts()
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
    }
    
    
    @MainActor func favorite(podcast: PodcastViewModel) async {
        
        isLoading = true
        do {
            let podcastModel = Podcast(podcastViewModel: podcast)
            try await podcastsInteractor.favorite(podcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
    }
    
    
    @MainActor func unfavorite(podcast: PodcastViewModel) async {
        
        isLoading = true
        do {
            let podcastModel = Podcast(podcastViewModel: podcast)
            try await podcastsInteractor.unfavorite(podcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
        
    }
    
    
    @MainActor func fetchFavorites() async {
        
        isLoading = true
        do {
            try await podcastsInteractor.fetchFavorites()
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
    }
    
    
    @MainActor func isfavorite(podcast: PodcastViewModel) async -> Bool {
        
        isLoading = true
        do {
            let podcastModel = Podcast(podcastViewModel: podcast)
            return try await podcastsInteractor.isFavorite(podcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
        return false
    }
    
    
    // MARK: - Private methods
    
    
    private func setupSubscriptions() {
        
        podcastsInteractor
            .podcasts
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handleFetchedPodcasts)
            .store(in: &cancellable)
            

        podcastsInteractor
            .favoritePodcasts
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handleFavoritePodcasts)
            .store(in: &cancellable)
        
    }
    
    private func handleError(_ completion: Subscribers.Completion<Error>) {
        switch completion {
            case .finished:
                print("Finished")
            case .failure(_):
                print("Failure")
        }
    }
    
    
    private func handleFavoritePodcasts(_ podcasts: [Podcast]) {
        
        self.favoritePodcasts = podcasts.map { PodcastViewModel(podcast: $0) }
    }
    
    
    private func handleFetchedPodcasts(_ podcasts: [Podcast]) {
        
        self.podcasts = podcasts.map { PodcastViewModel(podcast: $0) }
    }
    
    
    private func setupSearchText() {
        
        $searchText
            .filter{ $0.count > 2 }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .sink { [searchPodcasts] value in
                Task {
                    await searchPodcasts(value)
                }
            }
            .store(in: &cancellable)
        
        $searchText
            .filter{ $0.count <= 2 }
            .sink { [fetchPodcasts] value in
                Task {
                    await fetchPodcasts()
                }
            }
            .store(in: &cancellable)
        
    }
    
    private func searchPodcasts(forValue value: String) async {
        do {
            try await podcastsInteractor.searchPodcasts(forValue: value)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
    }
}
