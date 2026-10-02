import SwiftUI

/// Compact download control for an episode row: download, progress (tap to cancel), downloaded, or retry.
struct DownloadButton: View {
    @EnvironmentObject private var downloads: DownloadManager
    let episode: EpisodeViewModel
    /// Draws the icon on a small material disc, for overlaying on artwork.
    var onArtwork = false

    private var streamUrl: String { episode.streamUrl }

    var body: some View {
        let state = downloads.state(for: streamUrl)
        Group {
            switch state {
            case .notDownloaded:
                Button { downloads.download(episode) } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .accessibilityLabel("Download")
            case .downloading(let progress):
                Button { downloads.cancel(streamUrl) } label: {
                    ZStack {
                        Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: max(progress, 0.03))
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.accentColor)
                            .frame(width: 7, height: 7)
                    }
                    .frame(width: 22, height: 22)
                    .animation(.linear(duration: 0.2), value: progress)
                }
                .accessibilityLabel("Cancel download")
                .accessibilityValue("\(Int(progress * 100)) percent")
            case .downloaded:
                Image(systemName: "arrow.down.circle.fill")
                    .accessibilityLabel("Downloaded")
            case .failed:
                Button { downloads.download(episode) } label: {
                    Image(systemName: "exclamationmark.arrow.circlepath")
                }
                .accessibilityLabel("Download failed. Try again")
            }
        }
        .font(onArtwork ? .body : .title3)
        .foregroundStyle(state == .downloaded ? Color.accentColor : (onArtwork ? Color.primary : Color.secondary))
        .frame(width: onArtwork ? 30 : nil, height: onArtwork ? 30 : nil)
        .background {
            if onArtwork { Circle().fill(.regularMaterial) }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

extension DownloadState {
    /// Short status for VoiceOver values and captions, or nil when there is nothing to say.
    var statusDescription: String? {
        switch self {
        case .notDownloaded: return nil
        case .downloading(let progress): return "Downloading \(Int(progress * 100))%"
        case .downloaded: return "Downloaded"
        case .failed: return "Download failed"
        }
    }
}

extension View {
    /// Download actions for rows that combine their children into one VoiceOver element,
    /// which hides the row's own download button.
    func downloadAccessibilityActions(_ episode: EpisodeViewModel, downloads: DownloadManager) -> some View {
        let streamUrl = episode.streamUrl
        let state = downloads.state(for: streamUrl)
        return accessibilityActions {
            switch state {
            case .notDownloaded, .failed:
                Button("Download") { downloads.download(episode) }
            case .downloading:
                Button("Cancel Download") { downloads.cancel(streamUrl) }
            case .downloaded:
                Button("Remove Download") { downloads.remove(streamUrl) }
            }
        }
    }
}
