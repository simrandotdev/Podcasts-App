import SwiftUI

/// Downloaded episodes and downloads in progress. Storage and the Wi-Fi only setting live in Settings.
struct DownloadsScreen: View {
    @Environment(DownloadsViewModel.self) private var downloads
    @Environment(PlayerViewModel.self) private var player
    @Environment(HistoryViewModel.self) private var history
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?
    @State private var isConfirmingRemoveAll = false

    var body: some View {
        List {
            if !downloads.activeDownloads.isEmpty {
                Section {
                    ForEach(downloads.activeDownloads, id: \.episode.streamUrl) { item in
                        ActiveDownloadRow(episode: item.episode, state: item.state,
                                          isWaitingForWiFi: downloads.isWaitingForWiFi)
                    }
                } header: {
                    sectionHeader("Downloading")
                }
            }

            Section {
                if downloads.library.isEmpty {
                    emptyState
                } else {
                    ForEach(downloads.library) { item in
                        DownloadedRow(episode: item.episode, fileSize: item.fileSize,
                                      isOnAir: player.isOnAir(item.episode))
                            .episodeRowActions(play: { play(item.episode) }, showDetails: { detailsEpisode = item.episode })
                    }
                    .onDelete { offsets in
                        let library = downloads.library
                        for index in offsets { downloads.remove(library[index].episode) }
                    }
                }
            } header: {
                sectionHeader("On Your Device")
            }

            if downloads.unidentifiedCount > 0 {
                Section {
                    HStack {
                        Label(downloads.unidentifiedCount == 1 ? "1 episode" : "\(downloads.unidentifiedCount) episodes",
                              systemImage: "questionmark.circle")
                        Spacer()
                        Text(Self.formattedSize(downloads.unidentifiedBytes))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    Button("Remove Earlier Downloads", role: .destructive) {
                        downloads.removeUnidentified()
                    }
                } header: {
                    sectionHeader("Earlier Downloads")
                } footer: {
                    Text("These were downloaded before episode details were saved. Open each episode's podcast and they'll move to On Your Device automatically.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Downloads 📥")
        // Loading the listening history identifies downloads saved before episode details were recorded.
        .task { await history.fetchHistory() }
        .toolbar {
            if !downloads.library.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Remove All", role: .destructive) { isConfirmingRemoveAll = true }
                }
            }
        }
        .confirmationDialog("Remove all downloaded episodes?", isPresented: $isConfirmingRemoveAll,
                            titleVisibility: .visible) {
            Button("Remove \(downloads.library.count) Episodes", role: .destructive) {
                downloads.removeAll()
            }
        } message: {
            Text("This frees \(Self.formattedSize(downloads.totalBytes)). You can download them again later.")
        }
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { play(episode) }
                .environment(player)
                .environment(downloads)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.heavy).monospaced())
            .foregroundStyle(Color.onAir)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.onAir)
                .accessibilityHidden(true)
            Text("No downloads yet")
                .font(.headline)
            Text("Tap the download button on any episode to listen without a connection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// Plays (or resumes) the episode, with the other downloads as the queue.
    private func play(_ episode: EpisodeViewModel) {
        maximizePlayerView(episode, downloads.library.map(\.episode))
    }

    static func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct DownloadedRow: View {
    let episode: EpisodeViewModel
    let fileSize: Int64
    let isOnAir: Bool

    var body: some View {
        HStack(spacing: 12) {
            PodcastArtwork(urlString: episode.imageUrl)
                .frame(width: 56, height: 56)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if !episode.author.isEmpty {
                        Text(episode.author.uppercased())
                            .font(.caption2.weight(.heavy).monospaced())
                            .foregroundStyle(Color.onAir)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if isOnAir { OnAirBadge() }
                }
                Text(episode.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(episode.formattedDateString) · \(DownloadsScreen.formattedSize(fileSize))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(episode.title), \(episode.author)")
        .accessibilityValue([isOnAir ? "On air" : nil, DownloadsScreen.formattedSize(fileSize)]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Plays this episode")
        .accessibilityAddTraits(.isButton)
    }
}

private struct ActiveDownloadRow: View {
    @Environment(DownloadsViewModel.self) private var downloads
    let episode: EpisodeViewModel
    let state: DownloadState
    let isWaitingForWiFi: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(episode.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                switch state {
                case .downloading(let progress):
                    if isWaitingForWiFi && progress == 0 {
                        Label("Waiting for Wi-Fi", systemImage: "wifi.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView(value: progress).tint(Color.onAir)
                    }
                case .failed(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .notDownloaded, .downloaded:
                    EmptyView()
                }
            }
            Spacer(minLength: 8)
            switch state {
            case .failed:
                Button("Retry") { downloads.download(episode) }
                    .font(.subheadline.weight(.semibold))
            default:
                Button("Cancel") { downloads.cancel(episode) }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 2)
    }
}
