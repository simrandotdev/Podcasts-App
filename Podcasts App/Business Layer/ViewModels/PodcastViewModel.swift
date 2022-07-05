//
//  PodcastViewModel.swift
//  Podcasts App
//
//  Created by jc on 2020-07-08.
//  Copyright © 2020 Simran App. All rights reserved.
//

import Foundation

class PodcastViewModel {
    private let repo = PodcastsPersistantManager()
    
    var recordId: String?
    var title: String
    var author: String
    var image: String
    var numberOfEpisodes: String
    var rssFeedUrl: String
    
    init(title: String, author: String, image: String, totalEpisodes: Int, rssFeedUrl: String, recordId: String? = nil) {
        self.title = title
        self.author = author
        self.image = image
        self.numberOfEpisodes = "\(totalEpisodes) episodes"
        self.rssFeedUrl = rssFeedUrl
        self.recordId = recordId
    }
    
    init(podcast: Podcast) {
        self.recordId = podcast.recordId ?? ""
        self.title = podcast.title ?? ""
        self.author = podcast.author ?? ""
        self.image = podcast.image ?? ""
        self.numberOfEpisodes = "\(podcast.totalEpisodes ?? 0) episodes" 
        self.rssFeedUrl = podcast.rssFeedUrl ?? ""
    }
}
