import GRDB
import XCTest
@testable import Podcasts_Bin

final class PersistanceManagerTests: XCTestCase {
    private func episode(streamUrl: String, podcastFeedUrl: String?) throws -> Episode {
        var fields: [String: Any] = ["title": "Episode", "subtitle": "", "pubDate": 0, "description": "",
                                     "author": "Author", "streamUrl": streamUrl]
        fields["podcastFeedUrl"] = podcastFeedUrl
        return try JSONDecoder().decode(Episode.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    func test_migrator_createsSchemaForNewDatabase() throws {
        let dbQueue = try DatabaseQueue()
        try PersistanceManager.migrator.migrate(dbQueue)
        try dbQueue.read { db in
            XCTAssertTrue(try db.tableExists("podcast"))
            XCTAssertTrue(try db.columns(in: "episode").map(\.name).contains("podcastFeedUrl"))
        }
    }

    func test_migrator_upgradesLegacyDatabaseAndKeepsHistory() throws {
        let dbQueue = try DatabaseQueue()
        // The schema the app created before it used migrations.
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE podcast (recordId TEXT, title TEXT, author TEXT, image TEXT, totalEpisodes INTEGER,
                                      rssFeedUrl TEXT PRIMARY KEY);
                CREATE TABLE episode (streamUrl TEXT PRIMARY KEY, title TEXT, subtitle TEXT, pubDate DATE,
                                      description TEXT, author TEXT, fileUrl TEXT, imageUrl TEXT);
                INSERT INTO episode (streamUrl, title, subtitle, pubDate, description, author)
                VALUES ('https://example.com/old.mp3', 'Old episode', '', '2024-01-01 00:00:00.000', '', 'Author');
                INSERT INTO podcast (title, rssFeedUrl) VALUES ('Saved show', 'https://example.com/feed');
                """)
        }

        try PersistanceManager.migrator.migrate(dbQueue)

        try dbQueue.read { db in
            let history = try Episode.fetchAll(db)
            XCTAssertEqual(history.map(\.title), ["Old episode"])
            XCTAssertNil(history.first?.podcastFeedUrl)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM podcast"), 1)
        }
    }

    func test_migrator_canRunAgainOnAMigratedDatabase() throws {
        let dbQueue = try DatabaseQueue()
        try PersistanceManager.migrator.migrate(dbQueue)
        XCTAssertNoThrow(try PersistanceManager.migrator.migrate(dbQueue))
    }

    func test_episode_roundTripsPodcastFeedUrl() throws {
        let dbQueue = try DatabaseQueue()
        try PersistanceManager.migrator.migrate(dbQueue)
        let saved = try episode(streamUrl: "https://example.com/new.mp3", podcastFeedUrl: "https://example.com/feed")

        try dbQueue.write { db in try saved.insert(db) }

        let loaded = try dbQueue.read { db in try Episode.fetchOne(db) }
        XCTAssertEqual(loaded?.podcastFeedUrl, "https://example.com/feed")
    }

    func test_episodeViewModel_carriesPodcastFeedUrlBothWays() throws {
        let original = try episode(streamUrl: "https://example.com/new.mp3", podcastFeedUrl: "https://example.com/feed")
        let viewModel = EpisodeViewModel(episode: original)
        XCTAssertEqual(viewModel.podcastFeedUrl, "https://example.com/feed")
        XCTAssertEqual(Episode(episodeViewModel: viewModel).podcastFeedUrl, "https://example.com/feed")
    }
}
