//
//  SearchPodcastsScreen.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct PodcastsScreen: View {
    
    
    // MARK: - States
    
    
    @EnvironmentObject var controller: PodcastsController
    
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        
        Group {
            if controller.isLoading {
                StandardListLoadingView()
            } else {
                List {
                    ForEach(controller.podcasts, id: \.rssFeedUrl) { podcast in
                        NavigationLink {
                            EpisodesScreen(podcast: podcast,
                                           maximizePlayerView: maximizePlayerView)
                            
                        } label: {
                            StandardListItemView(title: podcast.title,
                                                 subtitle: podcast.author,
                                                 moreInfo: podcast.numberOfEpisodes,
                                                 imageUrlString: podcast.image)
                            
                        }
                        .padding(.trailing)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                
            }
        }
        .navigationTitle("Hello Podcasts 👋")
        .searchable(text: $controller.searchText)
        .onAppear(perform: onAppear)
        .refreshable(action: fetchPodcasts)
    }
    
    
    // MARK: - Helper methods
    
    
    private func onAppear() {
        
        if controller.podcasts.count == 0 {
           fetchPodcasts()
        }
    }
    
    @Sendable private func fetchPodcasts() {
        
        Task {
            await controller.fetchPodcasts()
        }
    }
}


// MARK: - Preview


struct SearchPodcastsScreen_Previews: PreviewProvider {
    static var previews: some View {
        PodcastsScreen(maximizePlayerView: { _, _ in
            
        })
    }
}
