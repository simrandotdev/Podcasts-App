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
    
    
    // MARK: - UI Setup
    
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(controller.favoritePodcasts, id: \.rssFeedUrl) { podcast in
                    PodcastThumbnailCell(podcast: podcast)
                        .onTapGesture(perform: {
                            segeu(podcastViewModel: podcast)
                        })
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
    }
    
    
    // MARK: - Helper methods
    
    
    private func onAppear() {
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
