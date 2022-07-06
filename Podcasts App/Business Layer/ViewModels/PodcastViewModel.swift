//
//  PodcastViewModel.swift
//  Podcasts App
//
//  Created by jc on 2020-07-08.
//  Copyright © 2020 Simran App. All rights reserved.
//

import Foundation

class PodcastViewModel {
    
    // MARK: - Dependencies
    
    
    private let repo = PodcastsPersistantManager()
    
    
    // MARK: - Public properties
    
    
    var recordId: String?
    var title: String
    var author: String
    var image: String
    var totalEpisodes: Int
    var numberOfEpisodes: String
    var rssFeedUrl: String
    
    
    // MARK: - Initializers
    
    
    init(title: String, author: String, image: String, totalEpisodes: Int, rssFeedUrl: String, recordId: String? = nil) {
        self.title = title
        self.author = author
        self.image = image
        self.totalEpisodes = totalEpisodes
        self.numberOfEpisodes = "\(totalEpisodes) episodes"
        self.rssFeedUrl = rssFeedUrl
        self.recordId = recordId
    }
    
    init(podcast: Podcast) {
        self.recordId = podcast.recordId ?? ""
        self.title = podcast.title ?? ""
        self.author = podcast.author ?? ""
        self.image = podcast.image ?? ""
        self.totalEpisodes = podcast.totalEpisodes ?? 0
        self.numberOfEpisodes = "\(podcast.totalEpisodes ?? 0) episodes" 
        self.rssFeedUrl = podcast.rssFeedUrl ?? ""
    }
}
