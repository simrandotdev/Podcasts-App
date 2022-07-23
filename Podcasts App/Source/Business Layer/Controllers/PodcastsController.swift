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


// MARK: - PodcastControllable protocol


protocol PodcastControllable {
    
    var podcasts: [PodcastViewModel] { get set }
    var searchText: String { get set }
    
    var favoritePodcasts: [PodcastViewModel] { get set }
    
    func fetchPodcasts() async
    func favorite(podcast: PodcastViewModel) async
    func unfavorite(podcast: PodcastViewModel) async
    func isfavorite(podcast: PodcastViewModel) async -> Bool
    func fetchFavorites() async
}


// MARK: - PodcastControllable implementation


class PodcastsController: PodcastControllable, ObservableObject {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var interactor: PodcastsInteractor
    @Injected private var episodesInteractor: EpisodesInteractor
    
    
    
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
            try await interactor.fetchPodcasts()
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
            try await interactor.favorite(podcast: podcastModel)
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
            try await interactor.unfavorite(podcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
        
    }
    
    
    @MainActor func fetchFavorites() async {
        
        isLoading = true
        do {
            try await interactor.fetchFavorites()
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
            return try await interactor.isFavorite(podcast: podcastModel)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
        isLoading = false
        return false
    }
    
    
    // MARK: - Private methods
    
    
    private func setupSubscriptions() {
        
        interactor
            .$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] podcasts in
                self?.podcasts = podcasts.map { PodcastViewModel(podcast: $0) }
            }
            .store(in: &cancellable)
        
        interactor
            .$favoritePodcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] podcasts in
                self?.favoritePodcasts = podcasts.map { PodcastViewModel(podcast: $0) }
            }
            .store(in: &cancellable)
        
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
            try await interactor.searchPodcasts(forValue: value)
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
    }
}
