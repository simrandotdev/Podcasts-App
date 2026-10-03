//
//  EpisodesRepository.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation

// MARK: - EpisodesRepositoryProtocol


/// Episodes from a podcast's RSS feed, and the listening history kept in Core Data.
protocol EpisodesRepositoryProtocol {

    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode]
    func saveInHistory(episode: Episode) async throws
    func fetchHistory() async throws -> [Episode]
}


// MARK: - EpisodesRepositoryProtocol Implementation


final class EpisodesRepository: EpisodesRepositoryProtocol {


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


    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode] {
        guard !feedUrl.isEmpty else { return [] }
        return try await api.fetchEpisodesAsync(forPodcast: feedUrl)
    }


    /// Records a play. Playing an episode again replaces its details and moves it to the top.
    func saveInHistory(episode: Episode) async throws {
        guard !episode.streamUrl.isEmpty else { throw PersistenceError.missingIdentifier }
        let playedAt = now()
        try await store.perform { context in
            let entity = try context.fetch(HistoryEpisodeEntity.request(streamUrl: episode.streamUrl)).first
                ?? HistoryEpisodeEntity(context: context)
            entity.update(from: episode)
            entity.lastPlayedAt = playedAt
        }
    }


    /// The listening history, most recently played first.
    func fetchHistory() async throws -> [Episode] {
        try await store.perform { context in
            try context.fetch(HistoryEpisodeEntity.allRequest()).map(\.episode)
        }
    }
}
