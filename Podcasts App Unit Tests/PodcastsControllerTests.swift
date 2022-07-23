//
//  PodcastsControllerTests.swift
//  Podcasts App Unit Tests
//
//  Created by Simran Preet Singh Narang on 2022-07-22.
//  Copyright © 2022 Simran App. All rights reserved.
//

import XCTest
import Combine
@testable import Podcasts_Bin

class PodcastsControllerTests: XCTestCase {

    var sut: PodcastsController!
    
    override func setUpWithError() throws {
        
        sut = PodcastsController(podcastsInteractor: MockPodcastsInteractor(),
                                 episodesInteractor: MockEpisodesInteractor())
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


class MockPodcastsInteractor: PodcastsInteractable {
    
    var podcasts: CurrentValueSubject<[Podcast], Never> = CurrentValueSubject([])
    var favoritePodcasts: CurrentValueSubject<[Podcast], Never> = CurrentValueSubject([])
    
    func fetchPodcasts() async throws {
        
    }
    
    func searchPodcasts(forValue value: String) async throws {
        
    }
    
    func favorite(podcast: Podcast) async throws {
        
    }
    
    func unfavorite(podcast: Podcast) async throws {
        
    }
    
    func isFavorite(podcast: Podcast) async throws -> Bool {
        
        return false
    }
    
    func fetchFavorites() async throws {
        
    }
    
    
}


class MockEpisodesInteractor: EpisodesInteractable {
    
    var episodes: CurrentValueSubject<[Episode], Never> = CurrentValueSubject([])
    var recentlyPlayedEpisodes: CurrentValueSubject<[Episode], Never> = CurrentValueSubject([])
    
    func fetchEpisodes(forPodcast podcast: Podcast) async throws {
        
    }
    
    func searchEpisodes(forValue value: String) async throws {
        
    }
    
    func saveInHistory(episode: Episode) async throws {
        
    }
    
    func fetchEpisodesFromHistory() async throws {
        
    }
}
