//
//  SearchPodcastsScreen.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct SearchPodcastsScreen: View {
    
    
    // MARK: - States
    
    
    @StateObject var controller = SearchPodcastsController()
    
    
    // MARK: - Body
    
    
    var body: some View {
        
        List {
            ForEach(controller.podcasts, id: \.rssFeedUrl) { podcast in
                StandardListItemView(title: podcast.title,
                                     subtitle: podcast.author,
                                     moreInfo: podcast.numberOfEpisodes,
                                     imageUrlString: podcast.image)
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
        SearchPodcastsScreen()
    }
}
