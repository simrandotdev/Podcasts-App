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
                NavigationLink(destination:podcastsScreen) {
                    Label("Home", systemImage: "magnifyingglass")
                }
                
                NavigationLink(destination: favoritesScreen) {
                    Label("Favorites", systemImage: "heart.fill")
                }
                
                NavigationLink(destination: recentlyPlayedScreen) {
                    Label("Recently Played", systemImage: "music.mic")
                }
            }
            .navigationTitle("Menu")
            
            podcastsScreen
        }
    }
    
    private var tabView: some View {
        TabView {
            NavigationView {
                podcastsScreen
            }.tabItem {
                Label("Home", systemImage: "magnifyingglass")
            }
            .tag(0)
            
            NavigationView {
                favoritesScreen
            } .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .tag(1)
            
            
            NavigationView {
                recentlyPlayedScreen
            } .tabItem {
                Label("Recently Played", systemImage: "music.mic")
            }
            .tag(2)
        }
    }
    
    
    private var podcastsScreen: some View {
        PodcastsScreen(maximizePlayerView: maximizePlayerView)
            .environmentObject(podcastsController)
    }
    
    private var favoritesScreen: some View {
        FavoritesScreen(maximizePlayerView: maximizePlayerView)
            .environmentObject(podcastsController)
    }
    
    private var recentlyPlayedScreen: some View {
        RecentlyPlayedEpisodesScreen(maximizePlayerView: maximizePlayerView)
            .environmentObject(episodesController)
    }
}

struct AppTabView_Previews: PreviewProvider {
    static var previews: some View {
        AppTabView(maximizePlayerView: { _, _ in })
    }
}
