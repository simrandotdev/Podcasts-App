import SwiftUI

struct PlayerDetailsView: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let minimize: () -> Void
    @State private var scrubTime = 0.0
    @State private var isScrubbing = false

    var body: some View {
        VStack {
            HStack {
                Button(action: minimize) {
                    Label("Minimize player", systemImage: "chevron.down")
                }
                Spacer()
                Text("Now Playing").font(.headline)
                Spacer()
                Button { player.close() } label: {
                    Label("Close player", systemImage: "xmark")
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(PlayerButtonStyle())
            .padding(.horizontal)
            .contentShape(Rectangle())
            .gesture(DragGesture().onEnded { value in
                if value.translation.height > 60 { minimize() }
            })

            ScrollView {
                VStack(spacing: 24) {
                    PodcastArtwork(urlString: player.episode?.imageUrl)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .scaleEffect(player.isPlaying || reduceMotion ? 1 : 0.82)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75),
                                   value: player.isPlaying)
                        .padding(.vertical)

                    VStack(spacing: 8) {
                        Text(player.episode?.title ?? "")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(player.episode?.author ?? "")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack {
                        Slider(value: Binding(
                            get: { isScrubbing ? scrubTime : min(player.currentTime, max(player.duration, 1)) },
                            set: { scrubTime = $0 }
                        ), in: 0...max(player.duration, 1), onEditingChanged: { editing in
                            if editing { scrubTime = player.currentTime }
                            isScrubbing = editing
                            if !editing { player.seek(to: scrubTime) }
                        })
                        .disabled(player.duration <= 0)
                        .accessibilityLabel("Playback position")
                        .accessibilityValue(timeString(isScrubbing ? scrubTime : player.currentTime))
                        HStack {
                            Text(timeString(isScrubbing ? scrubTime : player.currentTime))
                            Spacer()
                            Text(player.duration > 0 ? timeString(player.duration) : "--:--")
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button { player.previous() } label: {
                            Label("Previous episode", systemImage: "backward.end.fill")
                        }.disabled(!player.canPlayPrevious)
                        Spacer(minLength: 0)
                        Button { player.skip(by: -15) } label: {
                            Label("Rewind 15 seconds", systemImage: "gobackward.15")
                        }
                        Spacer(minLength: 0)
                        Button { player.togglePlayback() } label: {
                            Label(player.isPlaying ? "Pause" : "Play",
                                  systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                        }
                        Spacer(minLength: 0)
                        Button { player.skip(by: 15) } label: {
                            Label("Forward 15 seconds", systemImage: "goforward.15")
                        }
                        Spacer(minLength: 0)
                        Button { player.next() } label: {
                            Label("Next episode", systemImage: "forward.end.fill")
                        }.disabled(!player.canPlayNext)
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .buttonStyle(PlayerButtonStyle())

                    if player.isBuffering {
                        ProgressView("Buffering…")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .onChange(of: player.episode?.streamUrl) { _ in isScrubbing = false }
    }

    private func timeString(_ seconds: Double) -> String {
        let total = Int(PlaybackController.validTime(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlaybackController
    let expand: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: expand) {
                HStack {
                    PodcastArtwork(urlString: player.episode?.imageUrl)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading) {
                        Text(player.episode?.title ?? "").font(.subheadline.weight(.semibold)).lineLimit(1)
                        Text(player.episode?.author ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand player: \(player.episode?.title ?? "")")
            Button { player.togglePlayback() } label: {
                Label(player.isPlaying ? "Pause" : "Play",
                      systemImage: player.isPlaying ? "pause.fill" : "play.fill")
            }
            Button { player.skip(by: 15) } label: {
                Label("Forward 15 seconds", systemImage: "goforward.15")
            }
            Button { player.close() } label: {
                Label("Close player", systemImage: "xmark")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(PlayerButtonStyle())
        .padding(8)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
        .simultaneousGesture(DragGesture().onEnded { value in
            if value.translation.height < -50 { expand() }
        })
    }
}

private struct PlayerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
