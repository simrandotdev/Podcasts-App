import SwiftUI

/// Horizontally scrolling cards for new episodes of the user's presets. Playing one takes it off the
/// shelf; opening its podcast clears all of that podcast's new episodes.
struct FreshOnAirRow: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var tracker: NewEpisodeTracker
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?

    private var episodes: [EpisodeViewModel] {
        tracker.freshEpisodes.map { EpisodeViewModel(episode: $0.episode) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(tracker.freshEpisodes) { fresh in
                    let episode = EpisodeViewModel(episode: fresh.episode)
                    FreshEpisodeCard(fresh: fresh, episode: episode)
                        .episodeRowActions(play: { play(episode) }, showDetails: { detailsEpisode = episode })
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { play(episode) }
                .environmentObject(player)
                .environmentObject(downloads)
        }
    }

    private func play(_ episode: EpisodeViewModel) {
        let queue = episodes
        tracker.markPlayed(episode.streamUrl)
        maximizePlayerView(episode, queue)
    }
}

private struct FreshEpisodeCard: View {
    @EnvironmentObject private var downloads: DownloadManager
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 150
    let fresh: FreshEpisode
    let episode: EpisodeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PodcastArtwork(urlString: episode.imageUrl ?? fresh.podcastImage)
                .aspectRatio(1, contentMode: .fit)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(alignment: .topLeading) { NewBadge().padding(6) }
                .overlay(alignment: .bottomTrailing) { DownloadButton(episode: episode, onArtwork: true) }
            Text(fresh.podcastTitle.uppercased())
                .font(.caption2.weight(.heavy).monospaced())
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
            Text(episode.title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(publishedAt, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New from \(fresh.podcastTitle): \(episode.title)")
        .accessibilityValue([publishedAt.formatted(.relative(presentation: .named)),
                             downloads.state(for: episode.streamUrl).statusDescription].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Plays this episode")
        .accessibilityAddTraits(.isButton)
        .downloadAccessibilityActions(episode, downloads: downloads)
    }

    /// Some feeds publish slightly ahead of time; show those as "now" rather than "in 2 hours".
    private var publishedAt: Date { min(episode.pubDate, Date()) }
}
