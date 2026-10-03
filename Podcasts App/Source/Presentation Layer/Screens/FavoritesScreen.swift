import SwiftUI

/// Favorites shown as numbered presets, like the preset buttons on a radio.
struct FavoritesScreen: View {
    @EnvironmentObject private var viewModel: FavoritesViewModel
    @EnvironmentObject private var player: PlayerViewModel
    @EnvironmentObject private var newEpisodes: NewEpisodesViewModel
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            if viewModel.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.favorites.enumerated()), id: \.element.rssFeedUrl) { index, podcast in
                            NavigationLink {
                                EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                            } label: {
                                StationTile(title: podcast.title, author: podcast.author, imageUrl: podcast.image,
                                            isOnAir: player.isOnAir(podcast), preset: index + 1,
                                            newCount: newEpisodes.newCount(for: podcast))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Favorites ❤️")
        .task { await viewModel.fetchFavorites() }
        .refreshable {
            await viewModel.fetchFavorites()
            await newEpisodes.refresh()
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
