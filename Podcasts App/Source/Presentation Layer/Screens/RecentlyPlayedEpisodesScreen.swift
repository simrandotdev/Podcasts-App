import SwiftUI

struct RecentlyPlayedEpisodesScreen: View {
    @EnvironmentObject private var episodesController: EpisodesController
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        List {
            if let error = episodesController.errorMessage {
                Text(error).foregroundStyle(.secondary)
            }
            ForEach(episodesController.recentlyPlayedEpisodes, id: \.streamUrl) { episode in
                Button {
                    maximizePlayerView(episode, episodesController.recentlyPlayedEpisodes)
                } label: {
                    StandardListItemView(title: episode.title, subtitle: episode.formattedDateString,
                                         moreInfo: episode.shortDescription,
                                         imageUrlString: episode.imageUrl ?? "")
                }
                .buttonStyle(.plain)
                .listRowCard()
            }
            if episodesController.recentlyPlayedEpisodes.isEmpty {
                Text("Episodes you play will appear here.").foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Recently Played 🎙")
        .task { await episodesController.fetchEpisodesFromHistory() }
        .refreshable { await episodesController.fetchEpisodesFromHistory() }
        .onReceive(NotificationCenter.default.publisher(for: .playbackHistoryChanged)) { _ in
            Task { await episodesController.fetchEpisodesFromHistory() }
        }
    }
}
