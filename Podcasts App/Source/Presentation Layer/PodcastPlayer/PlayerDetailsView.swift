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
                statusBadge
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
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            // Same red "on air" ring as the station tiles on the Podcasts screen.
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: player.isPlaying ? 4 : 0)
                        }
                        .scaleEffect(player.isPlaying || reduceMotion ? 1 : 0.88)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75),
                                   value: player.isPlaying)
                        .padding(.top)

                    stationDisplay

                    VStack(spacing: 4) {
                        Slider(value: Binding(
                            get: { isScrubbing ? scrubTime : min(player.currentTime, max(player.duration, 1)) },
                            set: { scrubTime = $0 }
                        ), in: 0...max(player.duration, 1), onEditingChanged: { editing in
                            if editing { scrubTime = player.currentTime }
                            isScrubbing = editing
                            if !editing { player.seek(to: scrubTime) }
                        })
                        .tint(Color.accentColor)
                        .disabled(player.duration <= 0)
                        .accessibilityLabel("Playback position")
                        .accessibilityValue(timeString(isScrubbing ? scrubTime : player.currentTime))
                        TunerScale()
                        timeReadout
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
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .background(Color.accentColor, in: Circle())
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

                    if let upNext {
                        Button { player.next() } label: {
                            HStack(spacing: 12) {
                                PodcastArtwork(urlString: upNext.imageUrl)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("UP NEXT").font(.caption2.weight(.heavy)).foregroundStyle(Color.accentColor)
                                    Text(upNext.title).font(.subheadline).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Up next: \(upNext.title)")
                        .accessibilityHint("Plays the next episode")
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

    @ViewBuilder private var statusBadge: some View {
        if player.isBuffering {
            OnAirBadge(text: "TUNING IN…", color: .gray)
        } else if player.isPlaying {
            OnAirBadge()
        } else {
            OnAirBadge(text: "PAUSED", color: .gray)
        }
    }

    /// Dark "radio display" panel with the episode title, the show, and a level meter.
    private var stationDisplay: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.episode?.author.uppercased() ?? "")
                    .font(.caption.weight(.bold).monospaced())
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                Text(player.episode?.title ?? "")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            LevelMeter(isActive: player.isPlaying && !player.isBuffering && !reduceMotion)
                .frame(width: 36, height: 32)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var upNext: EpisodeViewModel? {
        guard player.canPlayNext, let current = player.episode,
              let index = player.queue.firstIndex(where: { $0.streamUrl == current.streamUrl }),
              index + 1 < player.queue.count else { return nil }
        return player.queue[index + 1]
    }

    /// Elapsed, total running time, and remaining time, labelled like a radio's display.
    private var timeReadout: some View {
        let elapsed = isScrubbing ? scrubTime : player.currentTime
        let hasDuration = player.duration > 0
        return HStack(alignment: .top) {
            timeColumn("ELAPSED", value: timeString(elapsed), alignment: .leading)
            Spacer()
            timeColumn("RUNNING TIME", value: hasDuration ? timeString(player.duration) : "--:--:--",
                       alignment: .center)
            Spacer()
            timeColumn("REMAINING", value: hasDuration ? "-" + timeString(player.duration - elapsed) : "--:--:--",
                       alignment: .trailing)
        }
        .padding(.top, 2)
    }

    private func timeColumn(_ label: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.capitalized)
        .accessibilityValue(value == "--:--:--" ? "Unknown" : value)
    }

    private func timeString(_ seconds: Double) -> String {
        let total = Int(PlaybackController.validTime(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let expand: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: expand) {
                HStack(spacing: 10) {
                    PodcastArtwork(urlString: player.episode?.imageUrl)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: player.isPlaying ? 2 : 0)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle().fill(statusColor).frame(width: 6, height: 6)
                            Text(statusLine)
                                .font(.caption2.weight(.heavy).monospaced())
                                .foregroundStyle(statusColor)
                                .lineLimit(1)
                        }
                        Text(player.episode?.title ?? "")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    LevelMeter(isActive: player.isPlaying && !player.isBuffering && !reduceMotion)
                        .frame(width: 22, height: 20)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand player: \(player.episode?.title ?? "")")
            .accessibilityValue(statusText)
            Button { player.togglePlayback() } label: {
                Label(player.isPlaying ? "Pause" : "Play",
                      systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor, in: Circle())
            }
            Button { player.skip(by: 15) } label: {
                Label("Forward 15 seconds", systemImage: "goforward.15")
            }
            Button { player.close() } label: {
                Label("Close player", systemImage: "xmark")
            }
            .foregroundStyle(.secondary)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(PlayerButtonStyle())
        .padding(8)
        .background(.regularMaterial)
        .overlay(alignment: .top) { tunerLine }
        .simultaneousGesture(DragGesture().onEnded { value in
            if value.translation.height < -50 { expand() }
        })
    }

    /// Red "needle" across the top edge showing how far into the episode playback is.
    private var tunerLine: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.secondary.opacity(0.2))
                Rectangle().fill(Color.accentColor)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }

    private var fraction: CGFloat {
        guard player.duration > 0 else { return 0 }
        return CGFloat(min(max(player.currentTime / player.duration, 0), 1))
    }

    private var statusText: String {
        if player.isBuffering { return "TUNING IN…" }
        return player.isPlaying ? "ON AIR" : "PAUSED"
    }

    /// Status plus the show name, e.g. "ON AIR · THE DAILY".
    private var statusLine: String {
        guard let author = player.episode?.author, !author.isEmpty else { return statusText }
        return "\(statusText) · \(author.uppercased())"
    }

    private var statusColor: Color {
        if player.isBuffering { return .secondary }
        return player.isPlaying ? Color.accentColor : .secondary
    }
}

/// Bouncing equalizer bars that sit still while paused.
private struct LevelMeter: View {
    let isActive: Bool
    private let barCount = 4

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.15)) { context in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { bar in
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(height: barHeight(bar, date: context.date))
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(.easeInOut(duration: 0.15), value: context.date)
        }
    }

    private func barHeight(_ bar: Int, date: Date) -> CGFloat {
        guard isActive else { return 4 }
        let t = date.timeIntervalSinceReferenceDate * Double(bar + 3)
        return 6 + 26 * CGFloat(abs(sin(t)))
    }
}

/// Tick marks under the scrubber, like the frequency scale on a radio dial.
private struct TunerScale: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<41, id: \.self) { tick in
                Rectangle()
                    .fill(Color.secondary.opacity(tick % 10 == 0 ? 0.8 : 0.4))
                    .frame(width: 1, height: tick % 10 == 0 ? 8 : tick % 5 == 0 ? 6 : 3)
                if tick < 40 { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, 2)
        .accessibilityHidden(true)
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
