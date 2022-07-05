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
    
    
    @StateObject var controller = SearchPodcastsController()
    
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        
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
        .searchable(text: $controller.searchText)
        .onAppear(perform: onAppear)
    }
    
    
    // MARK: - Helper methods
    
    
    private func onAppear() {
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
