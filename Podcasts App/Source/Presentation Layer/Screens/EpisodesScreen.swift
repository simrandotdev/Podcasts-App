import SwiftUI

/// A podcast presented as a radio station: a station header, then its episodes as the schedule.
struct EpisodesScreen: View {
    @EnvironmentObject private var podcastsController: PodcastsController
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var tracker: NewEpisodeTracker
    @StateObject private var episodesController = EpisodesController()
    @State private var isFavorite = false
    @State private var isUpdatingFavorite = false
    @State private var detailsEpisode: EpisodeViewModel?
    let podcast: PodcastViewModel
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                stationHeader
                    .padding(.bottom, 14)

                Text("Schedule")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                if let error = episodesController.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                    Button("Retry") { Task { await fetchEpisodes() } }
                }
                if episodesController.isLoading && episodesController.episodes.isEmpty {
                    ForEach(0..<8, id: \.self) { _ in
                        ScheduleRow(date: .now, title: "Episode title placeholder",
                                    summary: "A short description of the episode goes here.",
                                    isOnAir: false, progress: nil)
                    }
                    .redacted(reason: .placeholder)
                    .accessibilityHidden(true)
                }
                ForEach(episodesController.episodes, id: \.streamUrl) { episode in
                    ScheduleRow(date: episode.pubDate, title: episode.title, summary: episode.shortDescription,
                                isOnAir: isOnAir(episode), progress: player.progress(for: episode),
                                episode: episode)
                        .episodeRowActions(play: { play(episode) }, showDetails: { detailsEpisode = episode })
                }
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(podcast.title)
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode, fallbackImageUrl: podcast.image) { play(episode) }
                .environmentObject(player)
                .environmentObject(DownloadManager.shared)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: podcast.rssFeedUrl) { await fetchEpisodes() }
        // A podcast's episode list can identify downloads saved before episode details were recorded.
        .onReceive(episodesController.$episodes) { episodes in
            downloads.identifyDownloads(from: episodes)
            // Opening a podcast clears its NEW badge and its Fresh on Air episodes.
            if !episodes.isEmpty { tracker.markSeen(podcast.rssFeedUrl, episodeUrls: episodes.map(\.streamUrl)) }
        }
        .refreshable { await fetchEpisodes() }
    }

    private var stationHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                PodcastArtwork(urlString: podcast.image)
                    .frame(width: 128, height: 128)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: isStationOnAir ? 3 : 0)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    if isStationOnAir { OnAirBadge() }
                    Text(podcast.title)
                        .font(.title3.bold())
                        .lineLimit(3)
                    if !podcast.author.isEmpty {
                        Text(podcast.author.uppercased())
                            .font(.caption.weight(.heavy).monospaced())
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(2)
                    }
                    Text(podcast.numberOfEpisodes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Full-width row so the labels never wrap; stacks vertically at large text sizes.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { headerButtons }
                VStack(spacing: 10) { headerButtons }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var headerButtons: some View {
        Button { tuneIn() } label: {
            Label("Tune In", systemImage: "play.fill")
                .headerButtonLabel(foreground: .white, background: Color.accentColor)
        }
        .disabled(episodesController.episodes.isEmpty)
        .accessibilityHint("Plays the latest episode")

        Button { Task { await toggleFavorite() } } label: {
            Label(isFavorite ? "Saved Preset" : "Save Preset",
                  systemImage: isFavorite ? "star.fill" : "star")
                .headerButtonLabel(foreground: Color.accentColor, background: Color.accentColor.opacity(0.12))
        }
        .disabled(isUpdatingFavorite)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    /// The playing episode belongs to this podcast's schedule.
    private var isStationOnAir: Bool {
        guard player.isPlaying, let current = player.episode?.streamUrl else { return false }
        // The stream-URL check also covers history entries saved before feed URLs were recorded.
        return player.isOnAir(podcast) || episodesController.episodes.contains { $0.streamUrl == current }
    }

    private func isOnAir(_ episode: EpisodeViewModel) -> Bool {
        player.isPlaying && player.episode?.streamUrl == episode.streamUrl
    }

    private func tuneIn() {
        guard let latest = episodesController.episodes.first else { return }
        play(latest)
    }

    private func play(_ episode: EpisodeViewModel) {
        if player.episode?.streamUrl == episode.streamUrl {
            // Already loaded: keep the current position rather than reloading the item.
            player.play()
            maximizePlayerView(nil, nil)
        } else {
            maximizePlayerView(episode, episodesController.episodes)
        }
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

private extension View {
    /// Single-line capsule label that shares the row's width equally with its sibling.
    func headerButtonLabel(foreground: Color, background: Color) -> some View {
        font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .background(background, in: Capsule())
            .contentShape(Capsule())
    }
}

/// One slot in the station schedule: a date "time slot", the episode, and how much was heard.
private struct ScheduleRow: View {
    @EnvironmentObject private var downloads: DownloadManager
    let date: Date
    let title: String
    let summary: String
    let isOnAir: Bool
    let progress: Double?
    /// Shows the download control when set; nil for loading placeholders.
    var episode: EpisodeViewModel?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.accentColor)
                Text(date.formatted(.dateTime.day()))
                    .font(.title2.bold().monospacedDigit())
                Text(date.formatted(.dateTime.year()))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    if isOnAir { OnAirBadge() }
                }
                if !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                if let progress {
                    HStack(spacing: 8) {
                        ProgressView(value: progress).tint(Color.accentColor)
                        Text(status(progress))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
            }

            if let episode {
                DownloadButton(episode: episode)
                    .padding(.vertical, -6)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isOnAir ? 2 : 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(date.formatted(date: .long, time: .omitted))")
        .accessibilityValue(accessibilityStatus)
        .accessibilityHint("Plays this episode")
        .accessibilityAddTraits(.isButton)
        .modifier(DownloadActions(episode: episode, downloads: downloads))
    }

    private var accessibilityStatus: String {
        let download = episode.flatMap { downloads.state(for: $0.streamUrl).statusDescription }
        return [isOnAir ? "On air" : nil, progress.map(status), download].compactMap { $0 }.joined(separator: ", ")
    }

    private func status(_ progress: Double) -> String {
        progress >= 0.99 ? "Finished" : "\(Int(progress * 100))% played"
    }
}

/// Adds download VoiceOver actions only for rows that have an episode.
private struct DownloadActions: ViewModifier {
    let episode: EpisodeViewModel?
    let downloads: DownloadManager

    func body(content: Content) -> some View {
        if let episode {
            content.downloadAccessibilityActions(episode, downloads: downloads)
        } else {
            content
        }
    }
}
