//
//  EpisodesScreen.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct EpisodesScreen: View {
    
    // MARK: - States
    
    
    @StateObject private var controller = EpisodesController()
    
    
    // MARK: - Public properties
    
    
    var podcast: PodcastViewModel
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        List {
            ForEach(controller.episodes, id: \.streamUrl) { episode in
                StandardListItemView(title: episode.title,
                                     subtitle: episode.author,
                                     moreInfo: episode.shortDescription,
                                     imageUrlString: episode.imageUrl ?? "")
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .onTapGesture {
                    maximizePlayerView(episode, controller.episodes)
                }
                
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .searchable(text: $controller.searchText, placement: .toolbar)
        .navigationTitle(podcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }
    
    
    private func onAppear() {
        
        Task {
            await controller.fetchEpisodes(forPodcast: podcast)
        }
    }
}

struct EpisodesScreen_Previews: PreviewProvider {
    static var previews: some View {
        let podcast = Podcast(recordId: "1",
                              title: "",
                              author: "",
                              image: "",
                              totalEpisodes: 100,
                              rssFeedUrl: "")
        EpisodesScreen(podcast: PodcastViewModel(podcast: podcast)) { _, _ in
            
        }
    }
}