//
//  EpisodesManager.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import Combine

// MARK: - EpisodesManaging protocol

protocol EpisodesManaging {

    /// Sends after an episode is added to the listening history, on an arbitrary thread.
    var historyDidChange: AnyPublisher<Void, Never> { get }

    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode]
    func saveInHistory(episode: Episode) async throws
    func fetchHistory() async throws -> [Episode]
}


// MARK: - EpisodesManaging Implementation


final class EpisodesManager: EpisodesManaging {


    // MARK: - Dependencies


    private let repository: EpisodesRepositoryProtocol

    private let historySubject = PassthroughSubject<Void, Never>()

    var historyDidChange: AnyPublisher<Void, Never> { historySubject.eraseToAnyPublisher() }

    init(repository: EpisodesRepositoryProtocol) {
        self.repository = repository
    }


    // MARK: Public methods


    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode] {

        try await repository.fetchEpisodes(forFeedUrl: feedUrl)
    }


    func saveInHistory(episode: Episode) async throws {

        try await repository.saveInHistory(episode: episode)
        historySubject.send()
    }


    func fetchHistory() async throws -> [Episode] {

        try await repository.fetchHistory()
    }
}
