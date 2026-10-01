import SwiftUI

struct PodcastsScreen: View {
    @EnvironmentObject private var controller: PodcastsController
    @EnvironmentObject private var episodesController: EpisodesController
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        List {
            if controller.searchText.isEmpty && !recentEpisodes.isEmpty {
                Section {
                    RecentlyPlayedRow(episodes: recentEpisodes, maximizePlayerView: maximizePlayerView)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
                        .listRowSeparator(.hidden)
                } header: {
                    Text("Recently Played")
                }
            }
            Section {
                if controller.isLoading && controller.podcasts.isEmpty {
                    StandardListLoadingView()
                }
                if let error = controller.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                    Button("Retry") { Task { await controller.fetchPodcasts() } }
                }
                ForEach(controller.podcasts, id: \.rssFeedUrl) { podcast in
                    NavigationLink {
                        EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                    } label: {
                        StandardListItemView(title: podcast.title, subtitle: podcast.author,
                                             moreInfo: podcast.numberOfEpisodes, imageUrlString: podcast.image)
                    }
                    .padding(.trailing)
                    .listRowCard()
                }
            } header: {
                // While searching, the list shows search results rather than the popular chart.
                if controller.searchText.isEmpty {
                    Text("Most Popular")
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Hello Podcasts 👋")
        .searchable(text: $controller.searchText)
        .task {
            if controller.podcasts.isEmpty { await controller.fetchPodcasts() }
        }
        .task { await episodesController.fetchEpisodesFromHistory() }
        .refreshable {
            await controller.fetchPodcasts()
            await episodesController.fetchEpisodesFromHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playbackHistoryChanged)) { _ in
            Task { await episodesController.fetchEpisodesFromHistory() }
        }
    }

    private var recentEpisodes: [EpisodeViewModel] {
        Array(episodesController.recentlyPlayedEpisodes.prefix(10))
    }
}
