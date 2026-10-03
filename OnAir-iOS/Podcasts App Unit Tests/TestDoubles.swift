import Combine
import XCTest
@testable import Podcasts_Bin

// MARK: - Models

func makePodcast(_ feed: String = "https://example.com/feed", title: String = "Podcast title",
                 totalEpisodes: Int? = 1) -> Podcast {
    Podcast(recordId: feed, title: title, author: "Author", image: "https://example.com/art.jpg",
            totalEpisodes: totalEpisodes, rssFeedUrl: feed)
}

func makeEpisode(_ id: String, title: String? = nil, pubDate: Date = Date(timeIntervalSinceReferenceDate: 700_000_000),
                 podcastFeedUrl: String? = "https://example.com/feed") -> Episode {
    Episode(title: title ?? "Episode \(id)", subtitle: "Subtitle \(id)", pubDate: pubDate,
            description: "<p>Notes for \(id)</p>", author: "Author", streamUrl: "https://example.com/\(id).mp3",
            fileUrl: nil, imageUrl: "https://example.com/\(id).jpg", podcastFeedUrl: podcastFeedUrl)
}

// MARK: - Managers

final class MockPodcastsManager: PodcastsManaging {
    var shouldFail = false
    var lastQuery: String?
    var favorites: [Podcast] = []
    let podcast = makePodcast(title: "Podcast title")
    private let favoritesSubject = PassthroughSubject<Void, Never>()

    var favoritesDidChange: AnyPublisher<Void, Never> { favoritesSubject.eraseToAnyPublisher() }

    /// Simulates a favorite changing somewhere else in the app.
    func sendFavoritesDidChange() { favoritesSubject.send() }

    func fetchPodcasts() async throws -> [Podcast] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return [podcast]
    }

    func searchPodcasts(forValue value: String) async throws -> [Podcast] {
        lastQuery = value
        return [makePodcast("https://example.com/search", title: "Search result")]
    }

    func favorite(podcast: Podcast) async throws {
        if shouldFail { throw URLError(.cannotWriteToFile) }
        if !favorites.contains(where: { $0.rssFeedUrl == podcast.rssFeedUrl }) { favorites.append(podcast) }
        favoritesSubject.send()
    }

    func unfavorite(podcast: Podcast) async throws {
        if shouldFail { throw URLError(.cannotWriteToFile) }
        favorites.removeAll { $0.rssFeedUrl == podcast.rssFeedUrl }
        favoritesSubject.send()
    }

    func isFavorite(podcast: Podcast) async throws -> Bool {
        favorites.contains { $0.rssFeedUrl == podcast.rssFeedUrl }
    }

    func fetchFavorites() async throws -> [Podcast] {
        if shouldFail { throw URLError(.cannotOpenFile) }
        return favorites
    }
}

final class MockEpisodesManager: EpisodesManaging {
    var shouldFail = false
    var episodesByFeed: [String: [Episode]] = [:]
    var history: [Episode] = []
    private let historySubject = PassthroughSubject<Void, Never>()

    var historyDidChange: AnyPublisher<Void, Never> { historySubject.eraseToAnyPublisher() }

    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return episodesByFeed[feedUrl] ?? []
    }

    func saveInHistory(episode: Episode) async throws {
        history.removeAll { $0.streamUrl == episode.streamUrl }
        history.insert(episode, at: 0)
        historySubject.send()
    }

    func fetchHistory() async throws -> [Episode] {
        if shouldFail { throw URLError(.cannotOpenFile) }
        return history
    }
}

// MARK: - Repositories

final class MockPodcastsRepository: PodcastsRepositoryProtocol {
    var shouldFail = false
    var searches: [String] = []
    var trendingFetches = 0
    var favorites: [Podcast] = []

    func search(forValue value: String) async throws -> [Podcast] {
        searches.append(value)
        return [makePodcast(title: value)]
    }

    func fetchTrendingPodcasts() async throws -> [Podcast] {
        trendingFetches += 1
        return [makePodcast(title: "Trending")]
    }

    func fetchFavoritePodcasts() async throws -> [Podcast] { favorites }

    func isFavorite(podcast: Podcast) async throws -> Bool {
        favorites.contains { $0.rssFeedUrl == podcast.rssFeedUrl }
    }

    func favorite(podcast: Podcast) async throws {
        if shouldFail { throw PersistenceError.missingIdentifier }
        favorites.append(podcast)
    }

    func unfavorite(podcast: Podcast) async throws {
        if shouldFail { throw PersistenceError.missingIdentifier }
        favorites.removeAll { $0.rssFeedUrl == podcast.rssFeedUrl }
    }
}

final class MockEpisodesRepository: EpisodesRepositoryProtocol {
    var shouldFail = false
    var feeds: [String] = []
    var saved: [Episode] = []

    func fetchEpisodes(forFeedUrl feedUrl: String) async throws -> [Episode] {
        feeds.append(feedUrl)
        return [makeEpisode("from-feed", podcastFeedUrl: feedUrl)]
    }

    func saveInHistory(episode: Episode) async throws {
        if shouldFail { throw PersistenceError.missingIdentifier }
        saved.append(episode)
    }

    func fetchHistory() async throws -> [Episode] { saved.reversed() }
}

// MARK: - App-wide managers, isolated from the app's shared instances

/// Records nothing and grants nothing; for tests that don't check notifications.
struct SilentNotifier: NewEpisodeNotifying {
    func requestAuthorization() async -> Bool { false }
    func isAuthorized() async -> Bool { false }
    func notify(_ episodes: [FreshEpisode]) async {}
}

/// Temporary files and defaults for app-wide managers; call `tearDown()` when done.
@MainActor
final class IsolatedManagers {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("IsolatedManagers-\(UUID().uuidString)")
    let suite = "IsolatedManagers.\(UUID().uuidString)"
    lazy var defaults = UserDefaults(suiteName: suite)!
    lazy var downloadStore = DownloadStore(directory: directory.appendingPathComponent("Downloads"))

    func downloadManager() -> DownloadManager {
        DownloadManager(store: downloadStore, configuration: .ephemeral, defaults: defaults, monitorsNetwork: false)
    }

    /// A finished download with no episode details, like those saved before details were recorded.
    /// Call before creating the download manager, which reads the store when it starts.
    func storeUnidentifiedDownload(for streamUrl: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent(UUID().uuidString)
        try Data("audio".utf8).write(to: file)
        try downloadStore.store(file, for: streamUrl, mimeType: nil)
    }

    func newEpisodesManager(favorites: @escaping () -> [Podcast] = { [] },
                            feeds: @escaping (String) -> [Episode] = { _ in [] },
                            now: @escaping () -> Date = Date.init) -> NewEpisodesManager {
        NewEpisodesManager(stateURL: directory.appendingPathComponent("NewEpisodes.json"), defaults: defaults,
                           loadFavorites: { favorites() }, fetchEpisodes: { feeds($0) },
                           notifier: SilentNotifier(), now: now)
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suite)
    }
}

// MARK: - Waiting

/// Waits for state that updates asynchronously, such as a reload after a change notification.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline { return false }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return true
}
