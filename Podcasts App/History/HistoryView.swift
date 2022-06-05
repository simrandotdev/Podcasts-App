//
//  HistoryView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import Resolver

struct HistoryView: View {
    
    @Injected var persistanceManager: PodcastsPersistantManager
    @State private var episodes: [EpisodeViewModel] = []
    @State private var searchText: String = ""
    
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    var body: some View {
        List {
            ForEach(episodes, id: \.streamUrl) { episode in
                HistoryViewItem(episode: episode,
                                episodes: episodes,
                                maximizePlayerView: maximizePlayerView)
            }
        }
        .listStyle(.plain)
        .onAppear {
            load()
        }
    }
    
    private func load() {
        let x = persistanceManager.fetchAllRecentlyPlayedPodcasts()
        episodes = x?.map{ EpisodeViewModel(episode: $0)} ?? [EpisodeViewModel]()
    }
    
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(maximizePlayerView: {_,_ in })
    }
}
