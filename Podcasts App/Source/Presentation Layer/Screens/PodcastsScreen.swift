import SwiftUI

struct PodcastsScreen: View {
    @EnvironmentObject private var controller: PodcastsController
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        List {
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
        }
        .listStyle(.plain)
        .navigationTitle("Hello Podcasts 👋")
        .searchable(text: $controller.searchText)
        .task {
            if controller.podcasts.isEmpty { await controller.fetchPodcasts() }
        }
        .refreshable { await controller.fetchPodcasts() }
    }
}
