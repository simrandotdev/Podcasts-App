//
//  EpisodesManager.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation

// MARK: - EpisodesManaging protocol

protocol EpisodesManaging {

    /// A new stream for each caller, which delivers a value after an episode is added to the listening history.
    func historyChanges() -> AsyncStream<Void>

    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode]
    func saveInHistory(episode: Episode) async throws
    func fetchHistory() async throws -> [Episode]
}


// MARK: - EpisodesManaging Implementation


final class EpisodesManager: EpisodesManaging {


    // MARK: - Dependencies


    private let repository: EpisodesRepositoryProtocol

    private let historyBroadcaster = ChangeBroadcaster()

    init(repository: EpisodesRepositoryProtocol) {
        self.repository = repository
    }


    // MARK: Public methods


    func historyChanges() -> AsyncStream<Void> {

        historyBroadcaster.changes()
    }


    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode] {

        try await repository.fetchEpisodes(forFeedUrl: feedUrl)
    }


    func saveInHistory(episode: Episode) async throws {

        try await repository.saveInHistory(episode: episode)
        historyBroadcaster.send()
    }


    func fetchHistory() async throws -> [Episode] {

        try await repository.fetchHistory()
    }
}
