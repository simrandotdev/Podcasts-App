//
//  SearchPodcastsController.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Resolver
import Combine


// MARK: - SearchPodcastControllable protocol


protocol SearchPodcastControllable {
    
    var podcasts: [PodcastViewModel] { get set }
    var searchText: String { get set }
    
    func fetchPodcasts() async
}


// MARK: - SearchPodcastControllable implementation


class SearchPodcastsController: SearchPodcastControllable, ObservableObject {
    
    
    // MARK: - Dependencies
    
    
    @Injected private var interactor: PodcastsInteractor
    
    
    
    // MARK: - Publisher Properties
    
    
    @Published var podcasts: [PodcastViewModel] = []
    @Published var searchText: String = ""
    
    
    // MARK: - Private properties
    
    
    private var cancellable = Set<AnyCancellable>()
    
    
    
    // MARK: - Initializer and setups
    
    
    init() {
        setupSubscriptions()
        setupSearchText()
    }
    
    private func setupSubscriptions() {
        
        interactor
            .$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] podcasts in
                self?.podcasts = podcasts.map { PodcastViewModel(podcast: $0) }
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
    
    // MARK: - SearchPodcastControllable protocol implementation
    
    
    func fetchPodcasts() async {
        do {
            try await interactor.fetchPodcasts()
        } catch {
            // TODO: Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
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
