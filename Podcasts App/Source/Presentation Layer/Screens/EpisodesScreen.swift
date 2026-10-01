import SwiftUI

struct EpisodesScreen: View {
    @EnvironmentObject private var podcastsController: PodcastsController
    @StateObject private var episodesController = EpisodesController()
    @State private var isFavorite = false
    @State private var isUpdatingFavorite = false
    let podcast: PodcastViewModel
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        List {
            if episodesController.isLoading && episodesController.episodes.isEmpty {
                StandardListLoadingView()
            }
            if let error = episodesController.errorMessage {
                Text(error).foregroundStyle(.secondary)
                Button("Retry") { Task { await fetchEpisodes() } }
            }
            ForEach(episodesController.episodes, id: \.streamUrl) { episode in
                Button {
                    maximizePlayerView(episode, episodesController.episodes)
                } label: {
                    StandardListItemView(title: episode.title, subtitle: episode.formattedDateString,
                                         moreInfo: episode.shortDescription,
                                         imageUrlString: episode.imageUrl ?? podcast.image)
                }
                .buttonStyle(.plain)
                .listRowCard()
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await toggleFavorite() }
                } label: {
                    Label(isFavorite ? "Remove from favorites" : "Add to favorites",
                          systemImage: isFavorite ? "heart.fill" : "heart")
                }
                .disabled(isUpdatingFavorite)
            }
        }
        .navigationTitle(podcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: podcast.rssFeedUrl) { await fetchEpisodes() }
        .refreshable { await fetchEpisodes() }
    }

    private func fetchEpisodes() async {
        await episodesController.fetchEpisodes(forPodcast: podcast)
        isFavorite = await podcastsController.isfavorite(podcast: podcast)
    }

    private func toggleFavorite() async {
        isUpdatingFavorite = true
        defer { isUpdatingFavorite = false }
        if isFavorite {
            await podcastsController.unfavorite(podcast: podcast)
        } else {
            await podcastsController.favorite(podcast: podcast)
        }
        isFavorite = await podcastsController.isfavorite(podcast: podcast)
    }
}
