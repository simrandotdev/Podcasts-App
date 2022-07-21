//
//  HistoryScreen.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-20.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct RecentlyPlayedEpisodesScreen: View {
    
    
    // MARK: - States
    
    
    @StateObject private var episodesController = EpisodesController()
    
    // MARK: - Public properties
    
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    
    // MARK: - Body
    
    
    var body: some View {
        Group {
            if episodesController.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(episodesController.recentlyPlayedEpisodes, id: \.streamUrl) { episode in
                        StandardListItemView(title: episode.title,
                                             subtitle: episode.formattedDateString,
                                             moreInfo: episode.shortDescription,
                                             imageUrlString: episode.imageUrl ?? "")
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onTapGesture {
                            maximizePlayerView(episode, episodesController.episodes)
                        }
                        
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Recently Played")
        .onAppear(perform: onAppear)
        .refreshable(action: fetchEpisodesFromHistory)
    }
    
    
    private func onAppear() {
        
        fetchEpisodesFromHistory()
    }
    
    @Sendable private func fetchEpisodesFromHistory() {
        Task {
            await episodesController.fetchEpisodesFromHistory()
        }
    }
}

struct HistoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentlyPlayedEpisodesScreen(maximizePlayerView: {_, _ in })
    }
}
