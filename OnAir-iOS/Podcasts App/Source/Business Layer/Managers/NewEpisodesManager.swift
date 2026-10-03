import BackgroundTasks
import Foundation
import Resolver
import UserNotifications

/// An episode of a preset (favorite) podcast that appeared after the user last opened that podcast.
struct FreshEpisode: Codable, Identifiable {
    let episode: Episode
    let podcastTitle: String
    let podcastImage: String
    let podcastFeedUrl: String
    var id: String { episode.streamUrl }
}

/// Sends "new episode" notifications. A protocol so tests can record them instead.
protocol NewEpisodeNotifying {
    func requestAuthorization() async -> Bool
    func isAuthorized() async -> Bool
    func notify(_ episodes: [FreshEpisode]) async
}

/// Checks preset feeds for new episodes, for the NEW badges, the Fresh on Air shelf and notifications.
///
/// An episode is new when its stream URL wasn't in the feed the last time the user opened that
/// podcast *and* it's dated after that visit. Requiring both keeps undated episodes (which FeedKit
/// parsing dates "now") from looking new on every check. Views reach it through `NewEpisodesViewModel`.
@MainActor
final class NewEpisodesManager: ObservableObject {
    static let shared = NewEpisodesManager()
    static let refreshTaskIdentifier = "ca.bytesizedsoftware.hello-podcasts.refresh"
    static let notificationsKey = "newEpisodeNotificationsEnabled"
    /// Foreground checks are skipped if one ran this recently.
    static let foregroundRefreshInterval: TimeInterval = 15 * 60

    /// New episodes across all presets, newest first.
    @Published private(set) var freshEpisodes: [FreshEpisode] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?
    @Published private(set) var notificationsEnabled: Bool

    /// Persisted between launches so badges and the shelf show before the first check finishes.
    struct State: Codable {
        var lastSeen: [String: Date] = [:]
        /// Stream URLs in each feed when the user last opened it (or when tracking began).
        var known: [String: [String]] = [:]
        var fresh: [FreshEpisode] = []
        /// Episodes played from the shelf, so they don't come back on the next check.
        var dismissed: [String] = []
        /// Episodes already announced in a notification.
        var notified: [String] = []
        var lastRefresh: Date?
    }

    private var state: State
    private let stateURL: URL
    private let defaults: UserDefaults
    private let loadFavorites: () async throws -> [Podcast]
    private let fetchEpisodes: (String) async throws -> [Episode]
    private let notifier: NewEpisodeNotifying
    private let now: () -> Date
    /// The latest stream URLs fetched per feed, used to re-baseline when the user opens a podcast.
    private var latestUrls: [String: [String]] = [:]

    private static let maxFreshPerFeed = 10
    private static let maxRemembered = 500

    init(stateURL: URL = NewEpisodesManager.defaultStateURL,
         defaults: UserDefaults = .standard,
         loadFavorites: (() async throws -> [Podcast])? = nil,
         fetchEpisodes: ((String) async throws -> [Episode])? = nil,
         notifier: NewEpisodeNotifying = UserNotificationsNotifier(),
         now: @escaping () -> Date = Date.init) {
        self.stateURL = stateURL
        self.defaults = defaults
        self.loadFavorites = loadFavorites ?? {
            let podcasts: PodcastsManaging = Resolver.resolve()
            return try await podcasts.fetchFavorites()
        }
        self.fetchEpisodes = fetchEpisodes ?? { feedUrl in
            let episodes: EpisodesManaging = Resolver.resolve()
            return try await episodes.fetchEpisodes(forFeedUrl: feedUrl)
        }
        self.notifier = notifier
        self.now = now
        notificationsEnabled = defaults.bool(forKey: Self.notificationsKey)
        state = (try? Data(contentsOf: stateURL)).flatMap { try? JSONDecoder().decode(State.self, from: $0) } ?? State()
        freshEpisodes = state.fresh
        lastRefresh = state.lastRefresh
    }

    nonisolated static var defaultStateURL: URL {
        let support = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("NewEpisodes.json")
    }

    // MARK: - Queries

    /// Number of new episodes for a podcast, for its NEW badge.
    func newCount(for feedUrl: String) -> Int {
        freshEpisodes.filter { $0.podcastFeedUrl == feedUrl }.count
    }

    // MARK: - Checking for new episodes

    /// Checks unless a check ran recently; for app launch and returning to the foreground.
    func refreshIfStale() async {
        if let lastRefresh, now().timeIntervalSince(lastRefresh) < Self.foregroundRefreshInterval { return }
        await refresh()
    }

    /// Checks every preset's feed. Returns the episodes newly announced in notifications.
    @discardableResult
    func refresh() async -> [FreshEpisode] {
        guard !isRefreshing else { return [] }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let favorites = try? await loadFavorites() else { return [] }
        let feeds = favorites.compactMap { podcast -> (Podcast, String)? in
            guard let feed = podcast.rssFeedUrl, !feed.isEmpty else { return nil }
            return (podcast, feed)
        }

        // Fetch all feeds at once; a feed that fails keeps its previous results.
        let fetcher = fetchEpisodes
        let results = await withTaskGroup(of: (String, [Episode]?).self) { group in
            for (_, feed) in feeds {
                group.addTask { (feed, try? await fetcher(feed)) }
            }
            var results: [String: [Episode]] = [:]
            for await (feed, episodes) in group { if let episodes { results[feed] = episodes } }
            return results
        }

        let checkedAt = now()
        let favoriteFeeds = Set(feeds.map(\.1))
        var fresh = state.fresh.filter { favoriteFeeds.contains($0.podcastFeedUrl) }
        let dismissed = Set(state.dismissed)

        for (podcast, feed) in feeds {
            guard let episodes = results[feed] else { continue }
            let urls = episodes.map(\.streamUrl).filter { !$0.isEmpty }
            latestUrls[feed] = urls
            guard let lastSeen = state.lastSeen[feed] else {
                // First check for this preset: everything already there is old.
                state.lastSeen[feed] = checkedAt
                state.known[feed] = urls
                continue
            }
            let known = Set(state.known[feed] ?? [])
            let newEpisodes = episodes
                .filter { !$0.streamUrl.isEmpty && !known.contains($0.streamUrl) && !dismissed.contains($0.streamUrl) }
                .filter { $0.pubDate > lastSeen }
                .sorted { $0.pubDate > $1.pubDate }
                .prefix(Self.maxFreshPerFeed)
            fresh.removeAll { $0.podcastFeedUrl == feed }
            fresh += newEpisodes.map { episode in
                var episode = episode
                episode.podcastFeedUrl = feed
                return FreshEpisode(episode: episode, podcastTitle: podcast.title ?? "",
                                    podcastImage: podcast.image ?? "", podcastFeedUrl: feed)
            }
        }

        // Forget presets that were removed.
        for feed in state.lastSeen.keys where !favoriteFeeds.contains(feed) {
            state.lastSeen[feed] = nil
            state.known[feed] = nil
        }

        state.fresh = fresh.sorted { $0.episode.pubDate > $1.episode.pubDate }
        state.lastRefresh = checkedAt
        let alreadyNotified = Set(state.notified)
        let toAnnounce = state.fresh.filter { !alreadyNotified.contains($0.id) }
        // Record them even when notifications are off, so turning them on later doesn't announce a backlog.
        state.notified = Array((state.notified + toAnnounce.map(\.id)).suffix(Self.maxRemembered))
        publishAndSave()

        guard notificationsEnabled, !toAnnounce.isEmpty, await notifier.isAuthorized() else { return [] }
        await notifier.notify(toAnnounce)
        return toAnnounce
    }

    // MARK: - Clearing

    /// The user opened a podcast: its episodes are no longer new.
    func markSeen(_ feedUrl: String, episodeUrls: [String]) {
        guard state.lastSeen[feedUrl] != nil || state.fresh.contains(where: { $0.podcastFeedUrl == feedUrl }) else { return }
        state.lastSeen[feedUrl] = now()
        let urls = episodeUrls.isEmpty ? (latestUrls[feedUrl] ?? []) : episodeUrls
        state.known[feedUrl] = Array(Set((state.known[feedUrl] ?? []) + urls))
        state.fresh.removeAll { $0.podcastFeedUrl == feedUrl }
        publishAndSave()
    }

    /// The user played an episode from the shelf.
    func markPlayed(_ streamUrl: String) {
        guard state.fresh.contains(where: { $0.id == streamUrl }) else { return }
        state.fresh.removeAll { $0.id == streamUrl }
        state.dismissed = Array((state.dismissed + [streamUrl]).suffix(Self.maxRemembered))
        publishAndSave()
    }

    private func publishAndSave() {
        freshEpisodes = state.fresh
        lastRefresh = state.lastRefresh
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }

    // MARK: - Notifications

    /// Turns new-episode notifications on or off, asking for permission when turning them on.
    /// Returns whether they are on afterwards.
    @discardableResult
    func setNotificationsEnabled(_ isOn: Bool) async -> Bool {
        let enabled = isOn ? await notifier.requestAuthorization() : false
        notificationsEnabled = enabled
        defaults.set(enabled, forKey: Self.notificationsKey)
        return enabled
    }

    // MARK: - Background refresh

    /// Asks iOS to wake the app to check for new episodes. iOS decides the actual time.
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = now().addingTimeInterval(60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Runs when iOS grants a background refresh.
    func refreshInBackground() async {
        scheduleBackgroundRefresh()   // keep the chain going
        await refresh()
    }
}

/// Delivers notifications through UNUserNotificationCenter: one per podcast, grouped by podcast.
struct UserNotificationsNotifier: NewEpisodeNotifying {
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func notify(_ episodes: [FreshEpisode]) async {
        let byPodcast = Dictionary(grouping: episodes, by: \.podcastFeedUrl)
        for (feed, episodes) in byPodcast {
            guard let first = episodes.first else { continue }
            let content = UNMutableNotificationContent()
            content.title = first.podcastTitle.isEmpty ? "New episode" : "New on \(first.podcastTitle)"
            content.body = episodes.count == 1 ? first.episode.title : "\(episodes.count) new episodes, including \(first.episode.title)"
            content.sound = .default
            content.threadIdentifier = feed
            let request = UNNotificationRequest(identifier: "new-episodes-\(feed)-\(first.id)", content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}
