import SwiftUI

/// Favorites shown as numbered presets, like the preset buttons on a radio.
struct FavoritesScreen: View {
    @EnvironmentObject private var controller: PodcastsController
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var tracker: NewEpisodeTracker
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            if controller.favoritePodcasts.isEmpty && !controller.isLoading {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(controller.favoritePodcasts.enumerated()), id: \.element.rssFeedUrl) { index, podcast in
                            NavigationLink {
                                EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                            } label: {
                                StationTile(title: podcast.title, author: podcast.author, imageUrl: podcast.image,
                                            isOnAir: player.isOnAir(podcast), preset: index + 1,
                                            newCount: tracker.newCount(for: podcast.rssFeedUrl))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Favorites ❤️")
        .task { await controller.fetchFavorites() }
        .refreshable {
            await controller.fetchFavorites()
            await tracker.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "radio")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("No presets yet")
                .font(.headline)
            Text("Favorite a podcast from its episode list to save it as a preset here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
