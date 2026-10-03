//
//  PodcastsRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation

// MARK: - PodcastsRepositoryProtocol


/// Podcasts from the iTunes Search API, and favorites (presets) kept in Core Data.
protocol PodcastsRepositoryProtocol {

    func search(forValue value: String) async throws -> [Podcast]
    func fetchFavoritePodcasts() async throws -> [Podcast]
    func isFavorite(podcast: Podcast) async throws -> Bool
    func favorite(podcast: Podcast) async throws
    func unfavorite(podcast: Podcast) async throws
}


// MARK: - PodcastsRepositoryProtocol Implementation


final class PodcastsRepository: PodcastsRepositoryProtocol {


    // MARK: - Dependencies


    private let api: APIService
    private let store: CoreDataStack
    private let now: () -> Date

    init(api: APIService, store: CoreDataStack, now: @escaping () -> Date = Date.init) {
        self.api = api
        self.store = store
        self.now = now
    }


    // MARK: - Public methods


    func search(forValue value: String) async throws -> [Podcast] {
        try await api.fetchPodcastsAsync(searchText: value)
    }


    /// Favorites in the order they were saved.
    func fetchFavoritePodcasts() async throws -> [Podcast] {
        try await store.perform { context in
            try context.fetch(FavoritePodcastEntity.allRequest()).map(\.podcast)
        }
    }


    func isFavorite(podcast: Podcast) async throws -> Bool {
        guard let feedUrl = podcast.rssFeedUrl, !feedUrl.isEmpty else { return false }
        return try await store.perform { context in
            try context.count(for: FavoritePodcastEntity.request(rssFeedUrl: feedUrl)) > 0
        }
    }


    /// Saves a favorite. Saving one that already exists updates its details and keeps its preset number.
    func favorite(podcast: Podcast) async throws {
        guard let feedUrl = podcast.rssFeedUrl, !feedUrl.isEmpty else { throw PersistenceError.missingIdentifier }
        let favoritedAt = now()
        try await store.perform { context in
            let entity: FavoritePodcastEntity
            if let existing = try context.fetch(FavoritePodcastEntity.request(rssFeedUrl: feedUrl)).first {
                entity = existing
            } else {
                entity = FavoritePodcastEntity(context: context)
                entity.favoritedAt = favoritedAt
            }
            entity.update(from: podcast)
        }
    }


    func unfavorite(podcast: Podcast) async throws {
        guard let feedUrl = podcast.rssFeedUrl, !feedUrl.isEmpty else { return }
        try await store.perform { context in
            for entity in try context.fetch(FavoritePodcastEntity.request(rssFeedUrl: feedUrl)) {
                context.delete(entity)
            }
        }
    }
}
