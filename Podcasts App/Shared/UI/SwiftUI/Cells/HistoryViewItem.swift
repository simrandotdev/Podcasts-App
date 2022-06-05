//
//  HistoryViewItem.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-06-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct HistoryViewItem: View {
    
    var episode: EpisodeViewModel
    var episodes: [EpisodeViewModel]
    var maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: episode.imageUrl ?? ""))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 12) {
                Text(episode.title)
                    .font(.body)
                Text("\(episode.pubDate, format: .dateTime)")
                    .lineLimit(2)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.onTapGesture {
                maximizePlayerView(episode, episodes)
            }
        }
    }
}
