//
//  FavoritePodcastsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import Resolver

struct FavoritePodcastsView: View {
    
    @StateObject var viewModel = FavoritePodcastsViewModel()
    @State var selectedPodcastViewModel: PodcastViewModel? = nil
    @State var showPodcastDetailsView: Bool = false
    
    var maximizePlayer: ((EpisodeViewModel?, [EpisodeViewModel]?) -> Void)
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.favoritePodcasts, id: \.rssFeedUrl) { podcast in
                    PodcastThumbnailCell(podcast: podcast)
                        .onTapGesture(perform: {
                            segeu(podcastViewModel: podcast)
                        })
                }
            }
            .background(
                NavigationLink(isActive: $showPodcastDetailsView, destination: {
                    //viewModel: selectedPodcastViewModel,
//                maximizePlayer: maximizePlayer
                    PodcastDetailsView(viewModel: selectedPodcastViewModel,
                                       maximizePlayer: maximizePlayer,
                                       episodesListViewModel: PodcastDetailViewModel(),
                                       favoritePodcastsViewModel: viewModel)
                }, label: {
                    Text("")
                })
            )
            .padding()
            .onAppear {
                Task {
                    await viewModel.fetchFavoritePodcasts()
                }
            }
        }
    }
    
    private func segeu(podcastViewModel: PodcastViewModel) {
        selectedPodcastViewModel = podcastViewModel
        showPodcastDetailsView.toggle()
    }
}

struct FavoritePodcastsView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePodcastsView(maximizePlayer: {_,_ in })
    }
}


struct PodcastDetailsView: View {
    
    var viewModel: PodcastViewModel? = nil
    var maximizePlayer: ((EpisodeViewModel?, [EpisodeViewModel]?) -> Void)
    
    @ObservedObject var episodesListViewModel: PodcastDetailViewModel
    @ObservedObject var favoritePodcastsViewModel: FavoritePodcastsViewModel
    
    var body: some View {
        List {
            ForEach(episodesListViewModel.episodes, id: \.streamUrl) { episode in
                HistoryViewItem(episode: episode,
                                episodes: episodesListViewModel.episodesList,
                                maximizePlayerView: maximizePlayer)
            }
        }
        .listStyle(.plain)
        .navigationTitle(viewModel?.title ?? "")
        .onAppear {
            fetchEpisodes()
        }
    }
    
    private func fetchEpisodes() {
        Task {
            guard let viewModel = viewModel else {
                return
            }
            try await episodesListViewModel.fetchEpisodes(forPodcast: viewModel)
        }
    }
}
