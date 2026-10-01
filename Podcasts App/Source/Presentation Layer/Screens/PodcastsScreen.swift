import SwiftUI

struct PodcastsScreen: View {
    @EnvironmentObject private var controller: PodcastsController
    @EnvironmentObject private var episodesController: EpisodesController
    @EnvironmentObject private var player: PlaybackController
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if controller.searchText.isEmpty && !recentEpisodes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("Recently Played")
                        RecentlyPlayedRow(episodes: recentEpisodes, maximizePlayerView: maximizePlayerView)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    // While searching, the grid shows search results rather than the popular chart.
                    sectionHeader(controller.searchText.isEmpty ? "Stations" : "Results")
                    if let error = controller.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).foregroundStyle(.secondary)
                            Button("Retry") { Task { await controller.fetchPodcasts() } }
                        }
                        .padding(.horizontal)
                    }
                    stationGrid
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Hello Podcasts 👋")
        .searchable(text: $controller.searchText)
        .task {
            if controller.podcasts.isEmpty { await controller.fetchPodcasts() }
        }
        .task { await episodesController.fetchEpisodesFromHistory() }
        .refreshable {
            await controller.fetchPodcasts()
            await episodesController.fetchEpisodesFromHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playbackHistoryChanged)) { _ in
            Task { await episodesController.fetchEpisodesFromHistory() }
        }
    }

    private var stationGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            if controller.isLoading && controller.podcasts.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    StationTile(title: "Podcast title", author: "Author", imageUrl: "", isOnAir: false)
                }
                .redacted(reason: .placeholder)
                .accessibilityHidden(true)
            }
            ForEach(controller.podcasts, id: \.rssFeedUrl) { podcast in
                NavigationLink {
                    EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                } label: {
                    StationTile(title: podcast.title, author: podcast.author,
                                imageUrl: podcast.image, isOnAir: player.isOnAir(podcast))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .padding(.horizontal)
            .accessibilityAddTraits(.isHeader)
    }

    private var recentEpisodes: [EpisodeViewModel] {
        Array(episodesController.recentlyPlayedEpisodes.prefix(10))
    }
}

/// Square station tile: full-bleed artwork with the title on a dark band, plus an ON AIR badge
/// while one of the podcast's episodes is playing.
struct StationTile: View {
    let title: String
    let author: String
    let imageUrl: String
    let isOnAir: Bool
    /// Preset number shown as "P1", "P2"… in the top-leading corner, like a radio's preset buttons.
    var preset: Int?

    var body: some View {
        PodcastArtwork(urlString: imageUrl)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    if !author.isEmpty {
                        Text(author)
                            .font(.caption)
                            .lineLimit(1)
                            .opacity(0.8)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.black.opacity(0.6))
            }
            .overlay(alignment: .topTrailing) {
                if isOnAir { OnAirBadge().padding(8) }
            }
            .overlay(alignment: .topLeading) {
                if let preset {
                    Text("P\(preset)")
                        .font(.caption.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.red, lineWidth: isOnAir ? 3 : 0)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityTitle)
            .accessibilityValue(isOnAir ? "On air" : "")
    }

    private var accessibilityTitle: String {
        let name = author.isEmpty ? title : "\(title), \(author)"
        return preset.map { "Preset \($0), \(name)" } ?? name
    }
}

/// Radio-style status capsule; shared by the station tiles and the player.
struct OnAirBadge: View {
    var text = "ON AIR"
    var color = Color.red

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(.white).frame(width: 6, height: 6)
            Text(text).font(.caption2.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color, in: Capsule())
    }
}

extension PlaybackController {
    /// Episodes don't store their podcast's feed URL, so match the playing episode by author.
    func isOnAir(_ podcast: PodcastViewModel) -> Bool {
        guard isPlaying, let author = episode?.author, !author.isEmpty else { return false }
        return author.caseInsensitiveCompare(podcast.author) == .orderedSame
    }
}
