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
    
    @StateObject var viewModel = HistoryViewModel()
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    var body: some View {
        List {
            ForEach(viewModel.episodes, id: \.streamUrl) { episode in
                HistoryViewItem(episode: episode,
                                episodes: viewModel.episodes,
                                maximizePlayerView: maximizePlayerView)
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText)
        .onAppear {
            viewModel.loadRecentlyPlayedEpisodes()
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(maximizePlayerView: {_,_ in })
    }
}
