import SwiftUI

/// Horizontally scrolling cards for new episodes of the user's presets. Playing one takes it off the
/// shelf; opening its podcast clears all of that podcast's new episodes.
struct FreshOnAirRow: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(DownloadsViewModel.self) private var downloads
    @Environment(NewEpisodesViewModel.self) private var newEpisodes
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(newEpisodes.freshEpisodes) { fresh in
                    FreshEpisodeCard(fresh: fresh)
                        .episodeRowActions(play: { play(fresh.episode) }, showDetails: { detailsEpisode = fresh.episode })
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { play(episode) }
                .environment(player)
                .environment(downloads)
        }
    }

    private func play(_ episode: EpisodeViewModel) {
        let queue = newEpisodes.freshEpisodes.map(\.episode)
        newEpisodes.markPlayed(episode)
        maximizePlayerView(episode, queue)
    }
}

private struct FreshEpisodeCard: View {
    @Environment(DownloadsViewModel.self) private var downloads
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 150
    let fresh: NewEpisodesViewModel.Item

    private var episode: EpisodeViewModel { fresh.episode }

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
                             downloads.state(for: episode).statusDescription].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Plays this episode")
        .accessibilityAddTraits(.isButton)
        .downloadAccessibilityActions(episode, downloads: downloads)
    }

    /// Some feeds publish slightly ahead of time; show those as "now" rather than "in 2 hours".
    private var publishedAt: Date { min(episode.pubDate, Date()) }
}
