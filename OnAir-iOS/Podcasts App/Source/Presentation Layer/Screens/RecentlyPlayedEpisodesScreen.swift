import SwiftUI

/// Listening history styled as a station's broadcast log, newest first.
struct RecentlyPlayedEpisodesScreen: View {
    @Environment(HistoryViewModel.self) private var history
    @Environment(PlayerViewModel.self) private var player
    @Environment(DownloadsViewModel.self) private var downloads
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if let error = history.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                }
                if history.episodes.isEmpty {
                    emptyState
                } else {
                    Text("Broadcast Log")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    ForEach(history.episodes, id: \.streamUrl) { episode in
                        LogEntryRow(episode: episode, isOnAir: player.isOnAir(episode),
                                    progress: player.progress(for: episode))
                            .episodeRowActions(play: { resume(episode) }, showDetails: { detailsEpisode = episode })
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Recently Played 🎙")
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { resume(episode) }
                .environment(player)
                .environment(downloads)
        }
        .task { await history.fetchHistory() }
        .refreshable { await history.fetchHistory() }
    }

    /// Resumes the episode from its saved position, with the rest of the history as the queue.
    private func resume(_ episode: EpisodeViewModel) {
        maximizePlayerView(episode, history.episodes)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("Nothing on the log yet")
                .font(.headline)
            Text("Episodes you play will appear here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

private struct LogEntryRow: View {
    @Environment(DownloadsViewModel.self) private var downloads
    let episode: EpisodeViewModel
    let isOnAir: Bool
    let progress: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PodcastArtwork(urlString: episode.imageUrl)
                .frame(width: 72, height: 72)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if !episode.author.isEmpty {
                        Text(episode.author.uppercased())
                            .font(.caption2.weight(.heavy).monospaced())
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if isOnAir { OnAirBadge() }
                }
                Text(episode.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    ProgressView(value: progress ?? 0)
                        .tint(Color.accentColor)
                    Text(status)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                Text(episode.formattedDateString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            DownloadButton(episode: episode)
                .padding(.vertical, -6)
        }
        .padding(10)
        .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isOnAir ? 2 : 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(episode.title), \(episode.author)")
        .accessibilityValue([isOnAir ? "On air" : nil, status, downloads.state(for: episode).statusDescription]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Resumes playback")
        .accessibilityAddTraits(.isButton)
        .downloadAccessibilityActions(episode, downloads: downloads)
    }

    private var status: String {
        guard let progress else { return "Not started" }
        return progress >= 0.99 ? "Finished" : "\(Int(progress * 100))% played"
    }
}
