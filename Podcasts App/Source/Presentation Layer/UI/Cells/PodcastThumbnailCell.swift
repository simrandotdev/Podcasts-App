//
//  PodcastThumbnailCell.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-06-05.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct PodcastThumbnailCell: View {
    
    var podcast: PodcastViewModel
    
    var body: some View {
        
            ZStack {
                PodcastArtwork(urlString: podcast.image)
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
        
    }
    
    private func titleAuthorView(podcast: PodcastViewModel) -> some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                VStack {
                    Text(podcast.title)
                        .font(.body)
                    Text(podcast.author)
                        .font(.caption)
                }
                Spacer()
            }
            .padding([.top, .bottom], 10)
            .background(Color.white.opacity(0.5))
        }
    }
}

struct PodcastThumbnailCell_Previews: PreviewProvider {
    static var previews: some View {
        PodcastThumbnailCell(podcast: PodcastViewModel(title: "Podcast title", author: "Author", image: "", totalEpisodes: 25, rssFeedUrl: ""))
    }
}
