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
    
    
    func test_podcastsController_hasBeenSetup() {
        
        XCTAssertNotNil(sut)
    }

    
    func tests_podcastsProperty_hasZeroPodcasts_whenFetchPodcastsIsnotCalled() async throws {
        
        // Assert
        XCTAssert(sut.podcasts.count == 0)
    }
    
    
    func test_fetchPodcasts_setsPodcastsProperty_withGreaterThenZeroPodcasts() async throws {
        
        // Act
        await sut.fetchPodcasts()
        
        // Assert
        XCTAssert(sut.podcasts.count > 0)
    }
    
    
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


class MockPodcastsInteractor: PodcastsInteractable {
    func isFavorite(podcast: Podcast) async throws -> Bool {
        return false
    }
    
    func favorite(podcast: Podcast) async throws -> [Podcast] {
        return []
    }
    
    func unfavorite(podcast: Podcast) async throws -> [Podcast] {
        return []
    }
    
    func fetchFavorites() async throws -> [Podcast] {
        return []
    }
    
    
    func fetchPodcasts() async throws -> [Podcast] {
        
        let dummyPodcast = Podcast(recordId: "1",
                                   title: "Podcast title",
                                   author: "Podcast author",
                                   image: "Podcast url",
                                   totalEpisodes: 1,
                                   rssFeedUrl: "Podcast rss feed")
        return [dummyPodcast]
    }
    
    func searchPodcasts(forValue value: String) async throws -> [Podcast] {
        return []
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
