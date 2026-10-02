import SwiftUI
import UIKit

extension EpisodeViewModel: Identifiable {
    /// Episodes are identified by their stream URL everywhere in the app.
    var id: String { streamUrl }
}

/// Full show notes for an episode, with a button to play or resume it.
struct EpisodeDetailsSheet: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.dismiss) private var dismiss
    let episode: EpisodeViewModel
    /// Artwork to fall back on when the episode has none of its own.
    var fallbackImageUrl: String?
    let play: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    playButton
                    Divider()
                    Text("SHOW NOTES")
                        .font(.caption.weight(.heavy).monospaced())
                        .foregroundStyle(Color.accentColor)
                        .accessibilityAddTraits(.isHeader)
                    Text(showNotes)
                        .font(.body)
                        .foregroundStyle(showNotesAreEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            PodcastArtwork(urlString: episode.imageUrl ?? fallbackImageUrl)
                .frame(width: 88, height: 88)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                if !episode.author.isEmpty {
                    Text(episode.author.uppercased())
                        .font(.caption.weight(.heavy).monospaced())
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(2)
                }
                Text(episode.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(episode.formattedDateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let progress, progress > 0 {
                    HStack(spacing: 8) {
                        ProgressView(value: progress).tint(Color.accentColor)
                        Text(progress >= 0.99 ? "Finished" : "\(Int(progress * 100))% played")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var playButton: some View {
        Button {
            dismiss()
            play()
        } label: {
            Label(playTitle, systemImage: isCurrentAndPlaying ? "waveform" : "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var progress: Double? { player.progress(for: episode) }

    private var isCurrentAndPlaying: Bool {
        player.isPlaying && player.episode?.streamUrl == episode.streamUrl
    }

    private var playTitle: String {
        if isCurrentAndPlaying { return "Now Playing" }
        if let progress, progress > 0, progress < 0.99 { return "Resume" }
        return "Play"
    }

    private var showNotes: String {
        showNotesAreEmpty ? "This episode has no show notes." : episode.description.htmlToPlainText()
    }

    private var showNotesAreEmpty: Bool {
        episode.description.htmlToPlainText().isEmpty
    }
}

extension View {
    /// Tap plays the episode; long-press shows its details. VoiceOver gets both as actions.
    func episodeRowActions(play: @escaping () -> Void, showDetails: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .onTapGesture(perform: play)
            .onLongPressGesture(minimumDuration: 0.4) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showDetails()
            }
            .accessibilityAction { play() }
            .accessibilityAction(named: "Show Details", showDetails)
    }
}
