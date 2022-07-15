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
    @StateObject private var podcastsController = PodcastsController()
    @State private var isFavorite = false
    
    // MARK: - Public properties
    
    
    var podcast: PodcastViewModel
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        Group {
            if controller.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(controller.episodes, id: \.streamUrl) { episode in
                        StandardListItemView(title: episode.title,
                                             subtitle: episode.formattedDateString,
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
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    onFavoriteButtonTap()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }
            }
        })
        .navigationTitle(podcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
        .refreshable(action: fetchEpisodes)
    }
    
    
    private func onAppear() {
        
        if controller.episodes.count == 0 {
            fetchEpisodes()
        }
    }
    
    @Sendable private func fetchEpisodes() {
        Task {
            await controller.fetchEpisodes(forPodcast: podcast)
            isFavorite = await podcastsController.isfavorite(podcast: podcast)
        }
    }
    
    private func onFavoriteButtonTap() {
        
        Task {
            if isFavorite {
                await podcastsController.unfavorite(podcast: podcast)
                isFavorite = await podcastsController.isfavorite(podcast: podcast)
            } else {
                await podcastsController.favorite(podcast: podcast)
                isFavorite = await podcastsController.isfavorite(podcast: podcast)
            }
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
