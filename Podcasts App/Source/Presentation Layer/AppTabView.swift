//
//  AppTabView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-08.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct AppTabView: View {
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        TabView {
            NavigationView {
                PodcastsScreen(maximizePlayerView: maximizePlayerView)
                    
            }.tabItem {
                Label("Home", systemImage: "magnifyingglass")
            }
            .tag(0)
            
            NavigationView {
                FavoritesScreen(maximizePlayerView: maximizePlayerView)
            } .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .tag(1)
            
        }
    }
}

struct AppTabView_Previews: PreviewProvider {
    static var previews: some View {
        AppTabView(maximizePlayerView: { _, _ in })
    }
}
