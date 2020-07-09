//
//  PodcastViewModel.swift
//  Podcasts App
//
//  Created by jc on 2020-07-08.
//  Copyright © 2020 Simran App. All rights reserved.
//

import Foundation

class PodcastViewModel {
    var title: String
    var author: String
    var image: String
    var numberOfEpisodes: Int
    var rssFeedUrl: String
    
    init(title: String, author: String, image: String, totalEpisodes: Int, rssFeedUrl: String) {
        self.title = title
        self.author = author
        self.image = image
        self.numberOfEpisodes = totalEpisodes
        self.rssFeedUrl = rssFeedUrl
    }
    
    init(podcast: Podcast) {
        self.title = podcast.title ?? ""
        self.author = podcast.author ?? ""
        self.image = podcast.image ?? ""
        self.numberOfEpisodes = podcast.totalEpisodes ?? 0
        self.rssFeedUrl = podcast.rssFeedUrl ?? ""
    }
}
