import SwiftUI

struct FavoritesScreen: View {
    @EnvironmentObject private var controller: PodcastsController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: horizontalSizeClass == .regular ? 4 : 2)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(controller.favoritePodcasts, id: \.rssFeedUrl) { podcast in
                    NavigationLink {
                        EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                    } label: {
                        PodcastThumbnailCell(podcast: podcast)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(podcast.title), \(podcast.author)")
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                }
            }
            .padding()
            if controller.favoritePodcasts.isEmpty && !controller.isLoading {
                Text("Favorite a podcast from its episode list to find it here.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Favorites ❤️")
        .task { await controller.fetchFavorites() }
        .refreshable { await controller.fetchFavorites() }
    }
}
