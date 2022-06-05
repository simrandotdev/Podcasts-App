//
//  FavoritePodcastsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct FavoritePodcastsView: View {
    
    @StateObject var viewModel = FavoritePodcastsViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.favoritePodcasts, id: \.rssFeedUrl) { podcast in
                    PodcastThumbnailCell(podcast: podcast)
                }
            }
            .padding()
            .onAppear {
                Task {
                    await viewModel.fetchFavoritePodcasts()
                }
            }
        }
    }
}

struct FavoritePodcastsView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePodcastsView()
    }
}
