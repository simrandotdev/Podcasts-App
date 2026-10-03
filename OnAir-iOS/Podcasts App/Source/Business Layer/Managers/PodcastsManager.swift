//
//  PodcastsManager.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Combine


// MARK: - PodcastsManaging protocol

protocol PodcastsManaging {

    /// Sends after a podcast is favorited or unfavorited, on an arbitrary thread.
    var favoritesDidChange: AnyPublisher<Void, Never> { get }

    func fetchPodcasts() async throws -> [Podcast]
    /// The Home list from the last successful `fetchPodcasts()`, to show before the latest one loads.
    func cachedPodcasts() async -> [Podcast]
    func searchPodcasts(forValue value: String) async throws -> [Podcast]
    func favorite(podcast: Podcast) async throws
    func unfavorite(podcast: Podcast) async throws
    func isFavorite(podcast: Podcast) async throws -> Bool
    func fetchFavorites() async throws -> [Podcast]
}


// MARK: - PodcastsManaging Implementation


final class PodcastsManager: PodcastsManaging {

    // MARK: - Dependencies


    private let repository: PodcastsRepositoryProtocol

    private let favoritesSubject = PassthroughSubject<Void, Never>()

    var favoritesDidChange: AnyPublisher<Void, Never> { favoritesSubject.eraseToAnyPublisher() }

    init(repository: PodcastsRepositoryProtocol) {
        self.repository = repository
    }


    // MARK: Public methods


    /// The Home list: podcasts that are trending now.
    func fetchPodcasts() async throws -> [Podcast] {

        try await repository.fetchTrendingPodcasts()
    }


    func cachedPodcasts() async -> [Podcast] {

        await repository.cachedTrendingPodcasts()
    }


    func searchPodcasts(forValue value: String) async throws -> [Podcast] {

        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try await fetchPodcasts()
        } else {
            return try await repository.search(forValue: value)
        }
    }


    func favorite(podcast: Podcast) async throws {

        try await repository.favorite(podcast: podcast)
        favoritesSubject.send()
    }


    func unfavorite(podcast: Podcast) async throws {

        try await repository.unfavorite(podcast: podcast)
        favoritesSubject.send()
    }


    func isFavorite(podcast: Podcast) async throws -> Bool {

        try await repository.isFavorite(podcast: podcast)
    }


    func fetchFavorites() async throws -> [Podcast] {

        try await repository.fetchFavoritePodcasts()
    }
}
