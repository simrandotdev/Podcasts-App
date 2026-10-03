//
//  SettingsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2021-12-21.
//  Copyright © 2021 Simran App. All rights reserved.
//

import SwiftUI
import Combine
import Resolver

/// Listening analytics, storage, and app settings.
struct SettingsView: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var tracker: NewEpisodeTracker
    @Environment(\.openURL) private var openURL
    /// Set when the user turned alerts on but iOS has notifications off for the app.
    @State private var notificationsDenied = false
    #if DEBUG
    @StateObject private var settingsViewModel = DebugSettingsViewModel()
    #endif
    @State private var cacheBytes = Int64(URLCache.shared.currentDiskUsage)
    @State private var isConfirmingDeleteDownloads = false
    @State private var isConfirmingClearCache = false

    var body: some View {
        List {
            Section {
                ListeningHeatmapView(heatmap: ListeningHeatmap(stats: stats))
                    .padding(.vertical, 8)
            } header: {
                sectionHeader("Listening Activity")
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
                Toggle(isOn: Binding(get: { tracker.notificationsEnabled }, set: { isOn in
                    Task {
                        let enabled = await tracker.setNotificationsEnabled(isOn)
                        notificationsDenied = isOn && !enabled
                    }
                })) {
                    Label("New Episode Alerts", systemImage: "bell.badge")
                }
                .tint(Color.accentColor)
                if notificationsDenied {
                    Button("Allow Notifications in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                Button {
                    Task { await tracker.refresh() }
                } label: {
                    HStack {
                        Label("Check Now", systemImage: "arrow.clockwise")
                        Spacer()
                        if tracker.isRefreshing {
                            ProgressView()
                        } else if let lastRefresh = tracker.lastRefresh {
                            Text(lastRefresh, format: .relative(presentation: .named))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(tracker.isRefreshing)
            } header: {
                sectionHeader("New Episodes")
            } footer: {
                Text(notificationsDenied
                     ? "Notifications are turned off for On Air in iOS Settings."
                     : "On Air checks your presets for new episodes in the background and marks them NEW. With alerts on, you'll get a notification for each podcast with something new.")
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

/// A year of listening, GitHub style: one column per week, one row per weekday, shaded by minutes.
/// Uses a validated one-hue ordinal ramp (Heat1–Heat4); empty days are neutral, not the ramp.
private struct ListeningHeatmapView: View {
    let heatmap: ListeningHeatmap
    @State private var selected: ListeningHeatmap.Day?
    @ScaledMetric(relativeTo: .caption2) private var cell: CGFloat = 13
    private let gap: CGFloat = 3

    private static let endID = "heatmap-end"
    private static let levelColors: [Color] = [Color(.systemGray5), Color("Heat1"), Color("Heat2"), Color("Heat3"), Color("Heat4")]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summary
            HStack(alignment: .top, spacing: gap + 2) {
                weekdayLabels
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            monthLabels
                            HStack(alignment: .top, spacing: gap) {
                                ForEach(Array(heatmap.weeks.enumerated()), id: \.offset) { _, week in
                                    weekColumn(week)
                                }
                                // Room for the last month's label, which can extend past its column.
                                // Scrolling to this keeps that label on screen.
                                Color.clear.frame(width: 16, height: 1).id(Self.endID)
                            }
                        }
                    }
                    .onAppear { proxy.scrollTo(Self.endID, anchor: .trailing) }
                }
            }
            HStack {
                Text(selectionText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Spacer(minLength: 8)
                legend
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Int(heatmap.totalSeconds / 60).formatted()) minutes in the last year")
                .font(.subheadline.weight(.semibold))
            // Three short stats side by side; stacked at large text sizes instead of wrapping mid-phrase.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { summaryStats }
                VStack(alignment: .leading, spacing: 6) { summaryStats }
            }
        }
    }

    @ViewBuilder private var summaryStats: some View {
        miniStat(heatmap.activeDays.formatted(), "Active days")
        miniStat(dayCount(heatmap.longestStreak), "Longest streak")
        miniStat(dayCount(heatmap.currentStreak), "Current streak")
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private func weekColumn(_ week: [ListeningHeatmap.Day?]) -> some View {
        VStack(spacing: gap) {
            ForEach(0..<7, id: \.self) { row in
                if let day = week[row] {
                    let isSelected = selected.map { heatmap.calendar.isDate($0.date, inSameDayAs: day.date) } ?? false
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(Self.levelColors[day.level])
                        .frame(width: cell, height: cell)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                    .strokeBorder(Color.primary, lineWidth: 1.5)
                            }
                        }
                        // A hit target larger than the square, without changing the layout.
                        .contentShape(Rectangle().inset(by: -gap / 2))
                        .onTapGesture { selected = isSelected ? nil : day }
                } else {
                    Color.clear.frame(width: cell, height: cell)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(weekLabel(week))
        .accessibilityValue(weekValue(week))
    }

    /// Short month name over the first column of each month, skipping ones that would collide.
    private var monthLabels: some View {
        HStack(spacing: gap) {
            ForEach(Array(monthLabelTexts.enumerated()), id: \.offset) { _, text in
                Text(text ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(width: cell, alignment: .leading)
            }
        }
        .accessibilityHidden(true)
    }

    private var monthLabelTexts: [String?] {
        var lastLabelled = -3
        return heatmap.weeks.enumerated().map { index, week in
            guard let first = week.compactMap({ $0 }).first else { return nil }
            let startsMonth = index == 0 || week.contains { day in
                day.map { heatmap.calendar.component(.day, from: $0.date) == 1 } ?? false
            }
            guard startsMonth, index - lastLabelled >= 3 else { return nil }
            lastLabelled = index
            let monthDay = week.compactMap { $0 }.first { heatmap.calendar.component(.day, from: $0.date) == 1 } ?? first
            return monthDay.date.formatted(.dateTime.month(.abbreviated))
        }
    }

    /// Every other weekday name, like GitHub, so the column stays narrow.
    private var weekdayLabels: some View {
        let symbols = heatmap.calendar.shortWeekdaySymbols
        let first = heatmap.calendar.firstWeekday - 1
        return VStack(alignment: .trailing, spacing: gap) {
            Text(" ").font(.caption2)   // aligns with the month label row
                .padding(.bottom, 4 - gap)
            ForEach(0..<7, id: \.self) { row in
                Text(row % 2 == 1 ? symbols[(first + row) % 7] : "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(height: cell)
            }
        }
        .fixedSize()
        .accessibilityHidden(true)
    }

    private var legend: some View {
        HStack(spacing: 3) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Self.levelColors[level])
                    .frame(width: 10, height: 10)
            }
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shading: none, under 15 minutes, 15 to 29, 30 to 59, and an hour or more")
    }

    private var selectionText: String {
        guard let selected else { return "Tap a day for details" }
        let date = selected.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return selected.minutes > 0 ? "\(date): \(selected.minutes) min" : "\(date): no listening"
    }

    private func dayCount(_ days: Int) -> String { days == 1 ? "1 day" : "\(days) days" }

    private func weekLabel(_ week: [ListeningHeatmap.Day?]) -> String {
        guard let first = week.compactMap({ $0 }).first else { return "" }
        return "Week of \(first.date.formatted(.dateTime.month(.wide).day()))"
    }

    private func weekValue(_ week: [ListeningHeatmap.Day?]) -> String {
        let days = week.compactMap { $0 }
        let minutes = Int(days.reduce(0) { $0 + $1.seconds } / 60)
        let active = days.filter { $0.level > 0 }.count
        guard active > 0 else { return "No listening" }
        return "\(minutes) minutes, on \(dayCount(active))"
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
