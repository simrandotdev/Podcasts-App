import SwiftUI

struct PodcastsScreen: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(HistoryViewModel.self) private var history
    @Environment(PlayerViewModel.self) private var player
    @Environment(NewEpisodesViewModel.self) private var newEpisodes
    let maximizePlayerView: (EpisodeViewModel?, [EpisodeViewModel]?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !viewModel.isSearching && !newEpisodes.freshEpisodes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("Fresh on Air")
                        FreshOnAirRow(maximizePlayerView: maximizePlayerView)
                    }
                }
                if !viewModel.isSearching && !history.recentEpisodes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("Recently Played")
                        RecentlyPlayedRow(episodes: history.recentEpisodes, maximizePlayerView: maximizePlayerView)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    // While searching, the grid shows search results rather than the trending stations.
                    sectionHeader(viewModel.isSearching ? "Results" : "Stations")
                    if viewModel.isShowingSavedStations && !viewModel.isSearching {
                        Label(viewModel.isLoading ? "Showing saved stations while the latest ones load"
                                                  : "Showing saved stations from your last visit",
                              systemImage: "clock.arrow.circlepath")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    if let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).foregroundStyle(.secondary)
                            Button("Retry") { Task { await viewModel.fetchPodcasts() } }
                        }
                        .padding(.horizontal)
                    }
                    stationGrid
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("On Air 📻")
        .searchable(text: $viewModel.searchText)
        .task { await viewModel.loadIfNeeded() }
        .task { await history.fetchHistory() }
        .refreshable {
            await viewModel.fetchPodcasts()
            await history.fetchHistory()
            await newEpisodes.refresh()
        }
    }

    private var stationGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            if viewModel.isLoading && viewModel.podcasts.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    StationTile(title: "Podcast title", author: "Author", imageUrl: "", isOnAir: false)
                }
                .redacted(reason: .placeholder)
                .accessibilityHidden(true)
            }
            ForEach(viewModel.podcasts, id: \.rssFeedUrl) { podcast in
                NavigationLink {
                    EpisodesScreen(podcast: podcast, maximizePlayerView: maximizePlayerView)
                } label: {
                    StationTile(title: podcast.title, author: podcast.author,
                                imageUrl: podcast.image, isOnAir: player.isOnAir(podcast),
                                newCount: newEpisodes.newCount(for: podcast))
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
    /// Episodes published since the user last opened this podcast.
    var newCount = 0

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
                VStack(alignment: .trailing, spacing: 4) {
                    if isOnAir { OnAirBadge() }
                    if newCount > 0 { NewBadge(count: newCount) }
                }
                .padding(8)
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
                    .strokeBorder(Color.onAir, lineWidth: isOnAir ? 3 : 0)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityTitle)
            .accessibilityValue(accessibilityStatus)
    }

    private var accessibilityStatus: String {
        let new = newCount == 0 ? nil : (newCount == 1 ? "1 new episode" : "\(newCount) new episodes")
        return [isOnAir ? "On air" : nil, new].compactMap { $0 }.joined(separator: ", ")
    }

    private var accessibilityTitle: String {
        let name = author.isEmpty ? title : "\(title), \(author)"
        return preset.map { "Preset \($0), \(name)" } ?? name
    }
}

/// "NEW" (or "3 NEW") on dark glass, readable on any artwork.
struct NewBadge: View {
    var count = 1

    var body: some View {
        Text(count > 1 ? "\(count) NEW" : "NEW")
            .font(.caption2.weight(.heavy).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.black.opacity(0.75), in: Capsule())
            .overlay { Capsule().strokeBorder(Color.onAir, lineWidth: 1.5) }
            .accessibilityHidden(true)
    }
}

/// Radio-style status capsule; shared by the station tiles and the player.
struct OnAirBadge: View {
    var text = "ON AIR"
    var color = Color.onAir

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
