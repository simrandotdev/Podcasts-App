//
//  BKFavoritePodcast.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-02-06.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation
import CloudKit
import BaadalKit

struct BKFavoritePodcast : RecordIDItem {
    
    var recordId: CKRecord.ID
    var title: String
    var author: String
    var image: String
    var totalEpisodes: Int
    var rssFeedUrl: String
    
    init(podcast: Podcast) {
        recordId = CKRecord.ID(recordName: podcast.recordId ?? "")
        title = podcast.title ?? ""
        author = podcast.author ?? ""
        image = podcast.image ?? ""
        totalEpisodes = podcast.totalEpisodes ?? 0
        rssFeedUrl = podcast.rssFeedUrl ?? ""
    }
}
