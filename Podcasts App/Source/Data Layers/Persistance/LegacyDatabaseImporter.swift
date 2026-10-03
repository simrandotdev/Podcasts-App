import CoreData
import Foundation
import SQLite3

/// Moves favorites and listening history out of the SQLite database the app kept with GRDB
/// (`Application Support/db.sqlite`) and into Core Data, once.
///
/// That database had a `podcast` table (favorites, keyed by `rssFeedUrl`) and an `episode` table
/// (history, keyed by `streamUrl`; `podcastFeedUrl` was added later), each listed in insertion order.
/// The old file is deleted only after the import is saved. If anything fails it stays, and the import
/// runs again on the next launch; rows already in Core Data are never imported twice.
struct LegacyDatabaseImporter {
    let databaseURL: URL
    private let now: () -> Date

    init(databaseURL: URL = LegacyDatabaseImporter.defaultDatabaseURL, now: @escaping () -> Date = Date.init) {
        self.databaseURL = databaseURL
        self.now = now
    }

    static var defaultDatabaseURL: URL {
        let support = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("db.sqlite")
    }

    /// Returns whether a legacy database was found and imported.
    @discardableResult
    func importIfNeeded(into stack: CoreDataStack) -> Bool {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return false }
        do {
            let (podcasts, episodes) = try readLegacyRecords()
            try stack.performAndWait { context in insert(podcasts: podcasts, episodes: episodes, into: context) }
            removeLegacyFiles()
            info("Imported \(podcasts.count) favorites and \(episodes.count) history entries into Core Data")
            return true
        } catch {
            err("Importing the legacy database failed", error.localizedDescription)
            return false
        }
    }

    // MARK: - Writing to Core Data

    private func insert(podcasts: [Podcast], episodes: [Episode], into context: NSManagedObjectContext) {
        let importedAt = now()
        // The old tables had no dates, only insertion order. Space the rows a second apart, oldest
        // first and all in the past, so presets keep their numbers and history keeps its order.
        func date(_ index: Int, of count: Int) -> Date { importedAt.addingTimeInterval(Double(index - count)) }

        for (index, podcast) in podcasts.enumerated() {
            guard let feedUrl = podcast.rssFeedUrl, !feedUrl.isEmpty,
                  (try? context.count(for: FavoritePodcastEntity.request(rssFeedUrl: feedUrl))) == 0 else { continue }
            let entity = FavoritePodcastEntity(context: context)
            entity.update(from: podcast)
            entity.favoritedAt = date(index, of: podcasts.count)
        }
        for (index, episode) in episodes.enumerated() {
            guard !episode.streamUrl.isEmpty,
                  (try? context.count(for: HistoryEpisodeEntity.request(streamUrl: episode.streamUrl))) == 0 else { continue }
            let entity = HistoryEpisodeEntity(context: context)
            entity.update(from: episode)
            entity.lastPlayedAt = date(index, of: episodes.count)
        }
    }

    private func removeLegacyFiles() {
        for suffix in ["", "-wal", "-shm", "-journal"] {
            try? FileManager.default.removeItem(atPath: databaseURL.path + suffix)
        }
    }

    // MARK: - Reading the legacy database

    /// Favorites and history, oldest first.
    private func readLegacyRecords() throws -> (podcasts: [Podcast], episodes: [Episode]) {
        var connection: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &connection, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let db = connection else {
            let message = connection.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            sqlite3_close(connection)
            throw LegacyDatabaseError.sqlite(message)
        }
        defer { sqlite3_close(db) }

        let podcasts = try rows(of: "podcast", in: db).map { row in
            Podcast(recordId: row["recordId"]?.string, title: row["title"]?.string, author: row["author"]?.string,
                    image: row["image"]?.string, totalEpisodes: row["totalEpisodes"]?.int,
                    rssFeedUrl: row["rssFeedUrl"]?.string)
        }
        let episodes = try rows(of: "episode", in: db).compactMap { row -> Episode? in
            guard let streamUrl = row["streamUrl"]?.string else { return nil }
            return Episode(title: row["title"]?.string ?? "", subtitle: row["subtitle"]?.string ?? "",
                           pubDate: row["pubDate"]?.date ?? now(), description: row["description"]?.string ?? "",
                           author: row["author"]?.string ?? "", streamUrl: streamUrl,
                           fileUrl: row["fileUrl"]?.string, imageUrl: row["imageUrl"]?.string,
                           podcastFeedUrl: row["podcastFeedUrl"]?.string)
        }
        return (podcasts, episodes)
    }

    /// Every row of `table` in insertion order, by column name. A missing table has no rows; the old
    /// app created an empty file before creating its tables.
    private func rows(of table: String, in db: OpaquePointer) throws -> [[String: Value]] {
        let exists = try query("SELECT name FROM sqlite_master WHERE type = 'table' AND name = '\(table)'", in: db)
        guard !exists.isEmpty else { return [] }
        return try query("SELECT * FROM \"\(table)\" ORDER BY rowid", in: db)
    }

    private func query(_ sql: String, in db: OpaquePointer) throws -> [[String: Value]] {
        var prepared: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &prepared, nil) == SQLITE_OK, let statement = prepared else {
            throw LegacyDatabaseError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        var rows: [[String: Value]] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return rows }
            guard result == SQLITE_ROW else { throw LegacyDatabaseError.sqlite(String(cString: sqlite3_errmsg(db))) }
            var row: [String: Value] = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                switch sqlite3_column_type(statement, column) {
                case SQLITE_INTEGER: row[name] = .integer(sqlite3_column_int64(statement, column))
                case SQLITE_FLOAT: row[name] = .real(sqlite3_column_double(statement, column))
                case SQLITE_TEXT: row[name] = sqlite3_column_text(statement, column).map { .text(String(cString: $0)) }
                default: row[name] = nil
                }
            }
            rows.append(row)
        }
    }

    /// A column value as SQLite stored it.
    private enum Value {
        case integer(Int64)
        case real(Double)
        case text(String)

        var string: String? {
            switch self {
            case .text(let text): return text
            case .integer(let number): return String(number)
            case .real(let number): return String(number)
            }
        }

        var int: Int? {
            switch self {
            case .integer(let number): return Int(number)
            case .real(let number): return Int(number)
            case .text(let text): return Int(text)
            }
        }

        /// GRDB wrote dates as "yyyy-MM-dd HH:mm:ss.SSS" in UTC, and read numbers as Unix timestamps.
        var date: Date? {
            switch self {
            case .integer(let seconds): return Date(timeIntervalSince1970: TimeInterval(seconds))
            case .real(let seconds): return Date(timeIntervalSince1970: seconds)
            case .text(let text): return Self.dateFormatters.lazy.compactMap { $0.date(from: text) }.first
            }
        }

        private static let dateFormatters: [DateFormatter] = [
            "yyyy-MM-dd HH:mm:ss.SSS", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd"
        ].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = format
            return formatter
        }
    }
}

enum LegacyDatabaseError: LocalizedError {
    case sqlite(String)

    var errorDescription: String? {
        switch self {
        case .sqlite(let message): return "The old database couldn't be read: \(message)"
        }
    }
}
