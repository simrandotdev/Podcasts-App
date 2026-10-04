//
//  PodcastsManager.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation


// MARK: - PodcastsManaging protocol

protocol PodcastsManaging {

    /// A new stream for each caller, which delivers a value after a podcast is favorited or unfavorited.
    func favoritesChanges() -> AsyncStream<Void>

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

    private let favoritesBroadcaster = ChangeBroadcaster()

    init(repository: PodcastsRepositoryProtocol) {
        self.repository = repository
    }


    // MARK: Public methods


    func favoritesChanges() -> AsyncStream<Void> {

        favoritesBroadcaster.changes()
    }


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
        favoritesBroadcaster.send()
    }


    func unfavorite(podcast: Podcast) async throws {

        try await repository.unfavorite(podcast: podcast)
        favoritesBroadcaster.send()
    }


    func isFavorite(podcast: Podcast) async throws -> Bool {

        try await repository.isFavorite(podcast: podcast)
    }


    func fetchFavorites() async throws -> [Podcast] {

        try await repository.fetchFavoritePodcasts()
    }
}
