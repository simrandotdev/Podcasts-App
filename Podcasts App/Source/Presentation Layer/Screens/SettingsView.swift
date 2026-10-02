//
//  SettingsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2021-12-21.
//  Copyright © 2021 Simran App. All rights reserved.
//

import Charts
import SwiftUI
import Combine
import Resolver

/// Listening analytics, storage, and app settings.
struct SettingsView: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var podcastsController: PodcastsController
    @EnvironmentObject private var episodesController: EpisodesController
    #if DEBUG
    @StateObject private var settingsViewModel = DebugSettingsViewModel()
    #endif
    @State private var cacheBytes = Int64(URLCache.shared.currentDiskUsage)
    @State private var isConfirmingDeleteDownloads = false
    @State private var isConfirmingClearCache = false

    private let tileColumns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: tileColumns, spacing: 12) {
                    StatTile(label: "Minutes Listened", value: minutes(stats.totalSeconds), systemImage: "headphones")
                    StatTile(label: "This Week", value: minutes(weekSeconds), unit: "min", systemImage: "calendar")
                    StatTile(label: "Episodes Played", value: count(episodesController.recentlyPlayedEpisodes.count),
                             systemImage: "music.mic")
                    StatTile(label: "Subscribed Podcasts", value: count(podcastsController.favoritePodcasts.count),
                             systemImage: "star.fill")
                    StatTile(label: "Downloaded Episodes", value: count(downloads.library.count),
                             systemImage: "arrow.down.circle.fill")
                    StatTile(label: "Download Storage", value: Self.formattedSize(downloads.totalBytes),
                             systemImage: "internaldrive")
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                .listRowBackground(Color.clear)
            } header: {
                sectionHeader("Your Listening")
            }

            Section {
                WeeklyListeningChart(days: stats.lastDays(7))
                    .padding(.vertical, 8)
            } header: {
                sectionHeader("Last 7 Days")
            } footer: {
                Text("Listening time is real time spent playing, so an hour at 2× counts as 30 minutes.")
            }

            Section {
                storageRow("Downloaded Episodes", bytes: downloads.totalBytes, systemImage: "arrow.down.circle")
                Button(role: .destructive) { isConfirmingDeleteDownloads = true } label: {
                    Label("Delete All Downloaded Episodes", systemImage: "trash")
                }
                .disabled(downloads.library.isEmpty)

                storageRow("Artwork Cache", bytes: cacheBytes, systemImage: "photo.on.rectangle")
                Button(role: .destructive) { isConfirmingClearCache = true } label: {
                    Label("Clear Cache", systemImage: "xmark.bin")
                }
                .disabled(cacheBytes == 0)
            } header: {
                sectionHeader("Storage")
            } footer: {
                Text("Clearing the cache removes saved artwork and other downloaded data, not your episodes. Artwork downloads again as you browse.")
            }

            Section {
                Toggle(isOn: Binding(get: { downloads.wifiOnly }, set: { downloads.setWiFiOnly($0) })) {
                    Label("Download on Wi-Fi Only", systemImage: "wifi")
                }
                .tint(Color.accentColor)
            } header: {
                sectionHeader("Downloads")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } header: {
                sectionHeader("About")
            }

            #if DEBUG
            Section {
                Toggle("Is User subscriber", isOn: $settingsViewModel.isUserSubscriber)
            } header: {
                sectionHeader("Debug")
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings ⚙️")
        .task {
            await podcastsController.fetchFavorites()
            await episodesController.fetchEpisodesFromHistory()
            cacheBytes = Int64(URLCache.shared.currentDiskUsage)
        }
        .confirmationDialog("Delete all downloaded episodes?", isPresented: $isConfirmingDeleteDownloads,
                            titleVisibility: .visible) {
            Button("Delete \(downloads.library.count) Episodes", role: .destructive) {
                downloads.removeAllDownloads()
            }
        } message: {
            Text("This frees \(Self.formattedSize(downloads.totalBytes)). You can download them again later.")
        }
        .confirmationDialog("Clear the cache?", isPresented: $isConfirmingClearCache, titleVisibility: .visible) {
            Button("Clear \(Self.formattedSize(cacheBytes))", role: .destructive) {
                URLCache.shared.removeAllCachedResponses()
                cacheBytes = Int64(URLCache.shared.currentDiskUsage)
            }
        }
    }

    // The player publishes its position every second while playing, so these stay current.
    private var stats: ListeningStats { player.listeningStats }
    private var weekSeconds: Double { stats.lastDays(7).reduce(0) { $0 + $1.seconds } }

    private func minutes(_ seconds: Double) -> String {
        Int(seconds / 60).formatted(.number)
    }

    private func count(_ value: Int) -> String { value.formatted(.number) }

    private func storageRow(_ title: String, bytes: Int64, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(Self.formattedSize(bytes))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.heavy).monospaced())
            .foregroundStyle(Color.accentColor)
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    static func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

/// A headline number with its label, styled like the player's station display.
private struct StatTile: View {
    let label: String
    let value: String
    var unit: String?
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title.bold().monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(unit.map { "\(value) \($0)" } ?? value)
    }
}

/// Minutes listened per day. One series, so no legend; the selected (or latest) day is labelled.
private struct WeeklyListeningChart: View {
    let days: [(day: Date, seconds: Double)]
    @State private var selectedDay: Date?

    private var isEmpty: Bool { days.allSatisfy { $0.seconds < 60 } }

    private var labelledDay: Date? {
        selectedDay ?? days.last(where: { $0.seconds >= 60 })?.day
    }

    var body: some View {
        if isEmpty {
            Text("Play an episode and your listening time will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            Chart(days, id: \.day) { item in
                let minutes = Int(item.seconds / 60)
                BarMark(x: .value("Day", item.day, unit: .day),
                        y: .value("Minutes", minutes),
                        width: .fixed(18))
                    .foregroundStyle(Color("ChartBar"))
                    .cornerRadius(4)
                    .annotation(position: .top, spacing: 4) {
                        if Calendar.current.isDate(item.day, inSameDayAs: labelledDay ?? .distantPast) {
                            Text("\(minutes) min")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel(item.day.formatted(.dateTime.weekday(.wide)))
                    .accessibilityValue("\(minutes) minutes")
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDay = Calendar.current.startOfDay(for: date)
                                }
                            }
                            .onEnded { _ in selectedDay = nil })
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Minutes listened in the last 7 days")
        }
    }
}

#if DEBUG
class DebugSettingsViewModel: ObservableObject {

    @Published var isUserSubscriber = false

    private var cancallable = Set<AnyCancellable>()

    init() {

        isUserSubscriber = Constants.InAppSubscribed.isUserSubscribed

        $isUserSubscriber
            .sink { isUserSubscriber in
            Constants.InAppSubscribed.isUserSubscribed = isUserSubscriber
        }
        .store(in: &cancallable)
    }
}
#endif
