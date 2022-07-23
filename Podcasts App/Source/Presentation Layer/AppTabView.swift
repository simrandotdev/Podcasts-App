//
//  AppTabView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-08.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct AppTabView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @StateObject var podcastsController = PodcastsController()
    @StateObject var episodesController = EpisodesController()
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        
        if verticalSizeClass == .regular && horizontalSizeClass == .regular {
            sideBarView
        } else {
            tabView
        }
    }
    
    
    private var sideBarView: some View {
        NavigationView {
            List {
                NavigationLink(destination:
                                PodcastsScreen(maximizePlayerView: maximizePlayerView)
                    .environmentObject(podcastsController)
                ) {
                    Label("Home", systemImage: "magnifyingglass")
                }
                
                NavigationLink(destination: FavoritesScreen(maximizePlayerView: maximizePlayerView)) {
                    Label("Favorites", systemImage: "heart.fill")
                }
                
                NavigationLink(destination: RecentlyPlayedEpisodesScreen(maximizePlayerView: maximizePlayerView)) {
                    Label("Recently Played", systemImage: "music.mic")
                }
            }
            .navigationTitle("Menu")
            
            PodcastsScreen(maximizePlayerView: maximizePlayerView)
                .environmentObject(podcastsController)
        }
    }
    
    private var tabView: some View {
        TabView {
            NavigationView {
                PodcastsScreen(maximizePlayerView: maximizePlayerView)
                    .environmentObject(podcastsController)
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
            
            
            NavigationView {
                RecentlyPlayedEpisodesScreen(maximizePlayerView: maximizePlayerView)
            } .tabItem {
                Label("Recently Played", systemImage: "music.mic")
            }
            .tag(2)
        }
    }
}

struct AppTabView_Previews: PreviewProvider {
    static var previews: some View {
        AppTabView(maximizePlayerView: { _, _ in })
    }
}
