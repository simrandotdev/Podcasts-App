import SQLite3
import XCTest
@testable import Podcasts_Bin

final class LegacyDatabaseImporterTests: XCTestCase {
    private var directory: URL!
    private var databaseURL: URL!
    private let importedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let api = APIService(session: URLSession(configuration: .ephemeral))

    /// The tables the app created with GRDB: the v1 migration's, without v2's `podcastFeedUrl`.
    private let v1Schema = """
        CREATE TABLE podcast (recordId TEXT, title TEXT, author TEXT, image TEXT, totalEpisodes INTEGER,
                              rssFeedUrl TEXT PRIMARY KEY);
        CREATE TABLE episode (streamUrl TEXT PRIMARY KEY, title TEXT, subtitle TEXT, pubDate DATE,
                              description TEXT, author TEXT, fileUrl TEXT, imageUrl TEXT);
        """

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyImporterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = directory.appendingPathComponent("db.sqlite")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private var importer: LegacyDatabaseImporter {
        LegacyDatabaseImporter(databaseURL: databaseURL, now: { [importedAt] in importedAt })
    }

    private func makeLegacyDatabase(_ sql: String) throws {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        XCTAssertEqual(sqlite3_open(databaseURL.path, &db), SQLITE_OK)
        var message: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &message)
        defer { sqlite3_free(message) }
        XCTAssertEqual(result, SQLITE_OK, message.map { String(cString: $0) } ?? "")
    }

    private func utc(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }

    func test_import_movesFavoritesAndHistoryAndKeepsTheirOrder() async throws {
        try makeLegacyDatabase(v1Schema + """
            ALTER TABLE episode ADD COLUMN podcastFeedUrl TEXT;
            INSERT INTO podcast VALUES ('1', 'First preset', 'Author', 'https://example.com/1.jpg', 12, 'https://example.com/1.xml');
            INSERT INTO podcast VALUES ('2', 'Second preset', NULL, NULL, NULL, 'https://example.com/2.xml');
            INSERT INTO episode VALUES ('https://example.com/old.mp3', 'Played first', 'Sub', '2024-01-01 00:00:00.000',
                                        'Notes', 'Author', NULL, 'https://example.com/old.jpg', 'https://example.com/1.xml');
            INSERT INTO episode VALUES ('https://example.com/new.mp3', 'Played last', '', '2024-02-03 04:05:06.789',
                                        '', 'Author', 'https://cdn.example.com/new.mp3', NULL, NULL);
            """)
        let stack = CoreDataStack(inMemory: true)

        XCTAssertTrue(importer.importIfNeeded(into: stack))

        let favorites = try await PodcastsRepository(api: api, store: stack).fetchFavoritePodcasts()
        XCTAssertEqual(favorites.map(\.title), ["First preset", "Second preset"])
        XCTAssertEqual(favorites.first?.recordId, "1")
        XCTAssertEqual(favorites.first?.totalEpisodes, 12)
        XCTAssertNil(favorites.last?.author)
        XCTAssertNil(favorites.last?.totalEpisodes)

        let history = try await EpisodesRepository(api: api, store: stack).fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Played last", "Played first"])
        XCTAssertEqual(history.last?.pubDate, utc("2024-01-01T00:00:00Z"))
        XCTAssertEqual(history.first?.pubDate.timeIntervalSince1970 ?? 0, 1_706_933_106.789, accuracy: 0.001)
        XCTAssertEqual(history.last?.description, "Notes")
        XCTAssertEqual(history.last?.podcastFeedUrl, "https://example.com/1.xml")
        XCTAssertNil(history.first?.podcastFeedUrl)
        XCTAssertEqual(history.first?.fileUrl, "https://cdn.example.com/new.mp3")
        XCTAssertFalse(FileManager.default.fileExists(atPath: databaseURL.path))
    }

    func test_import_readsDatabasesFromBeforeFeedUrlsWereRecorded() async throws {
        try makeLegacyDatabase(v1Schema + """
            INSERT INTO episode (streamUrl, title, subtitle, pubDate, description, author)
            VALUES ('https://example.com/old.mp3', 'Old episode', '', '2024-01-01 00:00:00.000', '', 'Author');
            """)
        let stack = CoreDataStack(inMemory: true)

        XCTAssertTrue(importer.importIfNeeded(into: stack))

        let history = try await EpisodesRepository(api: api, store: stack).fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Old episode"])
        XCTAssertNil(history.first?.podcastFeedUrl)
    }

    func test_newPlays_listAboveImportedHistory() async throws {
        try makeLegacyDatabase(v1Schema + """
            INSERT INTO episode (streamUrl, title, subtitle, pubDate, description, author)
            VALUES ('https://example.com/old.mp3', 'Imported', '', '2024-01-01 00:00:00.000', '', 'Author');
            """)
        let stack = CoreDataStack(inMemory: true)
        importer.importIfNeeded(into: stack)
        let repository = EpisodesRepository(api: api, store: stack, now: { [importedAt] in importedAt.addingTimeInterval(1) })

        try await repository.saveInHistory(episode: makeEpisode("new", title: "Played after updating"))

        let history = try await repository.fetchHistory()
        XCTAssertEqual(history.map(\.title), ["Played after updating", "Imported"])
    }

    func test_import_neverDuplicatesOrOverwritesExistingRows() async throws {
        try makeLegacyDatabase(v1Schema + """
            INSERT INTO podcast (title, rssFeedUrl) VALUES ('Legacy title', 'https://example.com/feed');
            """)
        let stack = CoreDataStack(inMemory: true)
        let repository = PodcastsRepository(api: api, store: stack)
        try await repository.favorite(podcast: makePodcast("https://example.com/feed", title: "Current title"))

        XCTAssertTrue(importer.importIfNeeded(into: stack))

        let favorites = try await repository.fetchFavoritePodcasts()
        XCTAssertEqual(favorites.map(\.title), ["Current title"])
    }

    func test_withoutLegacyDatabase_importsNothing() {
        XCTAssertFalse(importer.importIfNeeded(into: CoreDataStack(inMemory: true)))
    }

    func test_emptyLegacyFile_isRemoved() async throws {
        // The old app created an empty file before creating its tables.
        XCTAssertTrue(FileManager.default.createFile(atPath: databaseURL.path, contents: Data()))
        let stack = CoreDataStack(inMemory: true)

        XCTAssertTrue(importer.importIfNeeded(into: stack))

        let history = try await EpisodesRepository(api: api, store: stack).fetchHistory()
        XCTAssertTrue(history.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: databaseURL.path))
    }

    func test_unreadableLegacyFile_isKeptForTheNextLaunch() throws {
        try Data("not a database".utf8).write(to: databaseURL)

        XCTAssertFalse(importer.importIfNeeded(into: CoreDataStack(inMemory: true)))

        XCTAssertTrue(FileManager.default.fileExists(atPath: databaseURL.path))
    }
}
