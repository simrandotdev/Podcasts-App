import SwiftUI

/// Downloaded episodes, downloads in progress, storage used, and the Wi-Fi only setting.
struct DownloadsScreen: View {
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var episodesController: EpisodesController
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void
    @State private var detailsEpisode: EpisodeViewModel?
    @State private var isConfirmingRemoveAll = false

    private var downloadedEpisodes: [EpisodeViewModel] {
        downloads.library.map { EpisodeViewModel(episode: $0.episode) }
    }

    var body: some View {
        List {
            storageSection

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
                        let episode = EpisodeViewModel(episode: item.episode)
                        DownloadedRow(episode: episode, fileSize: item.fileSize,
                                      isOnAir: player.isPlaying && player.episode?.streamUrl == episode.streamUrl)
                            .episodeRowActions(play: { play(episode) }, showDetails: { detailsEpisode = episode })
                    }
                    .onDelete { offsets in
                        for index in offsets { downloads.remove(downloads.library[index].id) }
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
                        downloads.removeUnidentifiedDownloads()
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
        .task { await episodesController.fetchEpisodesFromHistory() }
        // Listening history can identify downloads saved before episode details were recorded.
        .onReceive(episodesController.$recentlyPlayedEpisodes) { downloads.identifyDownloads(from: $0) }
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
                downloads.removeAllDownloads()
            }
        } message: {
            Text("This frees \(Self.formattedSize(downloads.totalBytes)). You can download them again later.")
        }
        .sheet(item: $detailsEpisode) { episode in
            EpisodeDetailsSheet(episode: episode) { play(episode) }
                .environmentObject(player)
                .environmentObject(downloads)
        }
    }

    private var storageSection: some View {
        Section {
            HStack {
                Label("Storage Used", systemImage: "internaldrive")
                Spacer()
                Text(Self.formattedSize(downloads.totalBytes))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Toggle(isOn: Binding(get: { downloads.wifiOnly }, set: { downloads.setWiFiOnly($0) })) {
                Label("Download on Wi-Fi Only", systemImage: "wifi")
            }
            .tint(Color.accentColor)
        } header: {
            sectionHeader(downloads.library.count == 1 ? "1 Episode" : "\(downloads.library.count) Episodes")
        } footer: {
            Text(downloads.wifiOnly
                 ? "New downloads wait for Wi-Fi and won't use mobile data."
                 : "Downloads can use mobile data when Wi-Fi isn't available.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.heavy).monospaced())
            .foregroundStyle(Color.accentColor)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
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

    private func play(_ episode: EpisodeViewModel) {
        if player.episode?.streamUrl == episode.streamUrl {
            // Already loaded: keep the current position rather than reloading the item.
            player.play()
            maximizePlayerView(nil, nil)
        } else {
            maximizePlayerView(episode, downloadedEpisodes)
        }
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
                            .foregroundStyle(Color.accentColor)
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
    @EnvironmentObject private var downloads: DownloadManager
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
                        ProgressView(value: progress).tint(Color.accentColor)
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
                Button("Cancel") { downloads.cancel(episode.streamUrl) }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 2)
    }
}
