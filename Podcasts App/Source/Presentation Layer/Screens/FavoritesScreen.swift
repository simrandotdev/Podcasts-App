//
//  FavoritesScreen.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-06.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct FavoritesScreen: View {
    
    // MARK: - States
    
    
    @StateObject var controller = PodcastsController()
    @State var selectedPodcastViewModel: PodcastViewModel? = nil
    @State var showPodcastDetailsView: Bool = false
    
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    
    // MARK: - UI Setup
    
    
    private let compactColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    private let regularColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        
        ScrollView() {
            LazyVGrid(columns: horizontalSizeClass == .regular ? regularColumns : compactColumns) {
                ForEach(controller.favoritePodcasts, id: \.rssFeedUrl) { podcast in
                    PodcastThumbnailCell(podcast: podcast)
                        .onTapGesture(perform: {
                            segeu(podcastViewModel: podcast)
                        })
                        .padding(4)
                }
            }
            .background(
                NavigationLink(isActive: $showPodcastDetailsView, destination: {
                    if let selectedPodcastViewModel = selectedPodcastViewModel {
                        EpisodesScreen(podcast: selectedPodcastViewModel, maximizePlayerView: maximizePlayerView)
                    }
                }, label: {
                    Text("")
                })
            )
            .padding()
        }
        .onAppear(perform: onAppear)
        .refreshable(action: fetchFavorites)
    }
    
    
    // MARK: - Helper methods
    
    
    private func onAppear() {
        
        fetchFavorites()
    }
    
    
    @Sendable private func fetchFavorites() {
        
        Task {
            await controller.fetchFavorites()
        }
    }
    
    
    private func segeu(podcastViewModel: PodcastViewModel) {
        selectedPodcastViewModel = podcastViewModel
        showPodcastDetailsView.toggle()
    }
}

struct FavoritesScreen_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesScreen(maximizePlayerView: { _, _ in
            
        })
    }
}
