import SwiftUI

/// Horizontally scrolling cards for the most recently played episodes, each showing how much
/// has been listened to. Tapping a card resumes the episode from its saved position; long-pressing
/// shows its show notes.
struct RecentlyPlayedRow: View {
    @EnvironmentObject private var player: PlayerViewModel
    @EnvironmentObject private var downloads: DownloadsViewModel
    let episodes: [EpisodeViewModel]
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(episodes, id: \.streamUrl) { episode in
                    RecentEpisodeCard(episode: episode, progress: player.progress(for: episode))
                        .episodeRowActions(play: { resume(episode) }, showDetails: { detailsEpisode = episode })
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { resume(episode) }
                .environmentObject(player)
                .environmentObject(downloads)
        }
    }

    private func resume(_ episode: EpisodeViewModel) {
        maximizePlayerView(episode, episodes)
    }
}

struct RecentEpisodeCard: View {
    @EnvironmentObject private var downloads: DownloadsViewModel
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 140
    let episode: EpisodeViewModel
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PodcastArtwork(urlString: episode.imageUrl)
                .aspectRatio(1, contentMode: .fit)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .overlay(alignment: .bottomTrailing) {
                    DownloadButton(episode: episode, onArtwork: true)
                }
            ProgressView(value: progress ?? 0)
                .progressViewStyle(.linear)
            Text(episode.title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(episode.title)
        .accessibilityValue([progressDescription, downloads.state(for: episode).statusDescription]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Resumes playback")
        .accessibilityAddTraits(.isButton)
        .downloadAccessibilityActions(episode, downloads: downloads)
    }

    private var progressDescription: String {
        guard let progress else { return "Not started" }
        return progress >= 0.99 ? "Finished" : "\(Int(progress * 100)) percent played"
    }
}
