//
//  PersistanceManager.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import GRDB

class PersistanceManager {
    
    public static let shared = PersistanceManager()
    
    public var dbQueue: DatabaseQueue?
    
    private init() {
        let databaseURL = getDatabasePath()
        
        if let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            info(documentDirectoryPath)
        }
        
        dbQueue = try? DatabaseQueue(path: databaseURL)
        
        if let dbQueue {
            do {
                try Self.migrator.migrate(dbQueue)
            } catch {
                err("Database migration failed", error.localizedDescription)
            }
        }
    }
    
    /// Schema history. Never edit a registered migration; add a new one instead.
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // Databases created before migrations were introduced already have these tables,
        // so create them only if they are missing.
        migrator.registerMigration("v1_createPodcastAndEpisode") { db in
            try db.create(table: "podcast", ifNotExists: true) { t in
                t.column("recordId", .text)
                t.column("title", .text)
                t.column("author", .text)
                t.column("image", .text)
                t.column("totalEpisodes", .integer)
                t.column("rssFeedUrl", .text).primaryKey()
            }
            try db.create(table: "episode", ifNotExists: true) { t in
                t.column("streamUrl", .text).primaryKey()
                t.column("title", .text)
                t.column("subtitle", .text)
                t.column("pubDate", .date)
                t.column("description", .text)
                t.column("author", .text)
                t.column("fileUrl", .text)
                t.column("imageUrl", .text)
            }
        }
        
        // Lets the ON AIR badge match a playing episode to its podcast exactly.
        migrator.registerMigration("v2_addEpisodePodcastFeedUrl") { db in
            try db.alter(table: "episode") { t in
                t.add(column: "podcastFeedUrl", .text)
            }
        }
        
        return migrator
    }
    
    
    public func getDatabasePath() -> String {
        
        let databaseURL = try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("db.sqlite")
        
        // If DB file not present in file manager copy DB file to user document directory
        let fileManager = FileManager.default
        
        if  let databasePath = databaseURL?.path,
            fileManager.fileExists(atPath: databasePath) {
            return databasePath
        } else {
            err("FILE NOT AVAILABLE ... Copying")
            if fileManager.createFile(atPath: (databaseURL?.path)!, contents: Data(), attributes: nil) {
                return (databaseURL?.path)!
            }
        }
        return ""
    }
}
