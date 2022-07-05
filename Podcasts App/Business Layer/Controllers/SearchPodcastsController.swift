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

class SearchPodcastsController: ObservableObject {
    
    // MARK: - Dependencies
    @Injected private var interactor: SearchPodcastsInteractor
    
    @Published var podcasts: [PodcastViewModel] = []
    
    // MARK: - Private properties
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    func fetchPodcasts() async {
        do {
            try await interactor.fetchPodcasts()
        } catch {
            // Handle Error
            err("\(#function)" ,error.localizedDescription)
        }
    }
    
    private func setupSubscriptions() {
        
        interactor
            .$podcasts
            .sink { [weak self] podcasts in
                self?.podcasts = podcasts.map { PodcastViewModel(podcast: $0) }
            }
            .store(in: &cancellable)
            
    }
    
}
