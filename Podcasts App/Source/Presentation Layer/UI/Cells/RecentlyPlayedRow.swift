import SwiftUI

/// Horizontally scrolling cards for the most recently played episodes, each showing how much
/// has been listened to. Tapping a card resumes the episode from its saved position.
struct RecentlyPlayedRow: View {
    @EnvironmentObject private var player: PlaybackController
    let episodes: [EpisodeViewModel]
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(episodes, id: \.streamUrl) { episode in
                    Button { resume(episode) } label: {
                        RecentEpisodeCard(episode: episode, progress: player.progress(for: episode))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func resume(_ episode: EpisodeViewModel) {
        if player.episode?.streamUrl == episode.streamUrl {
            // Already loaded: keep the current position rather than reloading the item.
            player.play()
            maximizePlayerView(nil, nil)
        } else {
            maximizePlayerView(episode, episodes)
        }
    }
}

struct RecentEpisodeCard: View {
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 140
    let episode: EpisodeViewModel
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PodcastArtwork(urlString: episode.imageUrl)
                .aspectRatio(1, contentMode: .fit)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
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
        .accessibilityValue(progressDescription)
        .accessibilityHint("Resumes playback")
        .accessibilityAddTraits(.isButton)
    }

    private var progressDescription: String {
        guard let progress else { return "Not started" }
        return progress >= 0.99 ? "Finished" : "\(Int(progress * 100)) percent played"
    }
}
