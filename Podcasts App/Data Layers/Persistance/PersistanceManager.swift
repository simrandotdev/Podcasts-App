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

        let databaseURL = try? FileManager.default
            .url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("db.sqlite")
        dbQueue = try? DatabaseQueue(path: databaseURL?.path ?? "")

        try? dbQueue?.write { db in

            try? db.create(table: "podcast") { t in
                t.column("recordId", .text)
                t.column("title", .text)
                t.column("author", .text)
                t.column("image", .text)
                t.column("totalEpisodes", .integer)
                t.column("rssFeedUrl", .text).primaryKey()
            }
        }
    }
}
