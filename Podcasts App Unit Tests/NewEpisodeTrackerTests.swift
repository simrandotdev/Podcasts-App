import XCTest
@testable import Podcasts_Bin

@MainActor
final class NewEpisodeTrackerTests: XCTestCase {
    private var stateURL: URL!
    private var defaults: UserDefaults!
    private var suite: String!
    private var favorites: [Podcast] = []
    private var feeds: [String: [Episode]] = [:]
    private var failingFeeds: Set<String> = []
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var notifier: RecordingNotifier!

    private let feedA = "https://example.com/a.xml"
    private let feedB = "https://example.com/b.xml"

    override func setUp() async throws {
        stateURL = FileManager.default.temporaryDirectory.appendingPathComponent("NewEpisodeTrackerTests-\(UUID().uuidString).json")
        suite = "NewEpisodeTrackerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        notifier = RecordingNotifier()
        favorites = [podcast(feedA, title: "Show A"), podcast(feedB, title: "Show B")]
        feeds = [feedA: [episode("a1", daysAgo: 10)], feedB: [episode("b1", daysAgo: 5)]]
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: stateURL)
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeTracker() -> NewEpisodeTracker {
        NewEpisodeTracker(stateURL: stateURL, defaults: defaults,
                          loadFavorites: { [unowned self] in self.favorites },
                          fetchEpisodes: { [unowned self] feed in
                              if self.failingFeeds.contains(feed) { throw URLError(.notConnectedToInternet) }
                              return self.feeds[feed] ?? []
                          },
                          notifier: notifier,
                          now: { [unowned self] in self.clock })
    }

    private func podcast(_ feed: String, title: String) -> Podcast {
        Podcast(recordId: feed, title: title, author: "Author", image: "https://example.com/\(title).jpg",
                totalEpisodes: 1, rssFeedUrl: feed)
    }

    /// An episode dated relative to the test clock.
    private func episode(_ id: String, daysAgo: Double = 0, hoursAgo: Double = 0) -> Episode {
        let date = clock.addingTimeInterval(-(daysAgo * 86_400 + hoursAgo * 3_600))
        let data = try! JSONSerialization.data(withJSONObject: [
            "title": "Episode \(id)", "subtitle": "", "pubDate": date.timeIntervalSinceReferenceDate,
            "description": "", "author": "Author", "streamUrl": "https://example.com/\(id).mp3"
        ])
        return try! JSONDecoder().decode(Episode.self, from: data)
    }

    private func advance(hours: Double) { clock = clock.addingTimeInterval(hours * 3_600) }

    // MARK: - Detecting new episodes

    func test_firstCheck_treatsExistingEpisodesAsOld() async {
        let tracker = makeTracker()
        await tracker.refresh()
        XCTAssertTrue(tracker.freshEpisodes.isEmpty)
        XCTAssertEqual(tracker.newCount(for: feedA), 0)
        XCTAssertNotNil(tracker.lastRefresh)
    }

    func test_episodePublishedAfterBaseline_isFreshAndCounted() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        feeds[feedA]!.append(episode("a3", hoursAgo: 2))

        await tracker.refresh()

        XCTAssertEqual(tracker.freshEpisodes.map(\.episode.title), ["Episode a2", "Episode a3"], "Newest first")
        XCTAssertEqual(tracker.newCount(for: feedA), 2)
        XCTAssertEqual(tracker.newCount(for: feedB), 0)
        XCTAssertEqual(tracker.freshEpisodes.first?.podcastTitle, "Show A")
        XCTAssertEqual(tracker.freshEpisodes.first?.episode.podcastFeedUrl, feedA)
    }

    func test_undatedEpisodesAlreadyInFeed_neverLookNew() async {
        // FeedKit dates undated items "now", so they always look recent.
        feeds[feedA] = [episode("undated", hoursAgo: 0)]
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA] = [episode("undated", hoursAgo: 0)]

        await tracker.refresh()

        XCTAssertTrue(tracker.freshEpisodes.isEmpty)
    }

    func test_backCatalogAdditions_dontCountAsNew() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("old-reupload", daysAgo: 30))

        await tracker.refresh()

        XCTAssertTrue(tracker.freshEpisodes.isEmpty)
    }

    // MARK: - Clearing

    func test_openingThePodcast_clearsItsNewEpisodes() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        feeds[feedB]!.append(episode("b2", hoursAgo: 1))
        await tracker.refresh()

        tracker.markSeen(feedA, episodeUrls: feeds[feedA]!.map(\.streamUrl))
        advance(hours: 1)
        await tracker.refresh()

        XCTAssertEqual(tracker.newCount(for: feedA), 0)
        XCTAssertEqual(tracker.newCount(for: feedB), 1)
    }

    func test_playedEpisode_leavesTheShelfAndStaysOff() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        await tracker.refresh()

        tracker.markPlayed("https://example.com/a2.mp3")
        await tracker.refresh()

        XCTAssertTrue(tracker.freshEpisodes.isEmpty)
    }

    func test_removedPreset_dropsItsNewEpisodes() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        await tracker.refresh()

        favorites = [podcast(feedB, title: "Show B")]
        await tracker.refresh()

        XCTAssertTrue(tracker.freshEpisodes.isEmpty)
    }

    func test_failedFeed_keepsItsPreviousNewEpisodes() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        await tracker.refresh()

        failingFeeds = [feedA]
        await tracker.refresh()

        XCTAssertEqual(tracker.newCount(for: feedA), 1)
    }

    func test_state_survivesRelaunch() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        await tracker.refresh()

        let relaunched = makeTracker()

        XCTAssertEqual(relaunched.freshEpisodes.map(\.id), ["https://example.com/a2.mp3"])
        XCTAssertEqual(relaunched.lastRefresh, tracker.lastRefresh)
    }

    func test_refreshIfStale_skipsRecentChecks() async {
        let tracker = makeTracker()
        await tracker.refresh()
        feeds[feedA]!.append(episode("a2", hoursAgo: 0))
        advance(hours: 0.1)
        await tracker.refreshIfStale()
        let checkedAt = tracker.lastRefresh

        advance(hours: 1)
        await tracker.refreshIfStale()

        XCTAssertNotEqual(tracker.lastRefresh, checkedAt)
    }

    // MARK: - Notifications

    func test_notifications_offByDefault() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))

        let announced = await tracker.refresh()

        XCTAssertTrue(announced.isEmpty)
        XCTAssertTrue(notifier.sent.isEmpty)
    }

    func test_notifications_announceEachNewEpisodeOnce() async {
        let tracker = makeTracker()
        await tracker.setNotificationsEnabled(true)
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        feeds[feedB]!.append(episode("b2", hoursAgo: 2))

        await tracker.refresh()
        await tracker.refresh()

        XCTAssertEqual(notifier.sent.count, 1, "One batch, not repeated on the next check")
        XCTAssertEqual(Set(notifier.sent.first?.map(\.id) ?? []),
                       ["https://example.com/a2.mp3", "https://example.com/b2.mp3"])
    }

    func test_notifications_dontAnnounceBacklogWhenTurnedOnLater() async {
        let tracker = makeTracker()
        await tracker.refresh()
        advance(hours: 6)
        feeds[feedA]!.append(episode("a2", hoursAgo: 1))
        await tracker.refresh()

        await tracker.setNotificationsEnabled(true)
        await tracker.refresh()

        XCTAssertTrue(notifier.sent.isEmpty)
    }

    func test_notifications_staySilentWithoutPermission() async {
        notifier.grantsPermission = false
        let tracker = makeTracker()
        let enabled = await tracker.setNotificationsEnabled(true)
        XCTAssertFalse(enabled)
        XCTAssertFalse(tracker.notificationsEnabled)
        XCTAssertFalse(defaults.bool(forKey: NewEpisodeTracker.notificationsKey))
    }
}

private final class RecordingNotifier: NewEpisodeNotifying {
    var grantsPermission = true
    private(set) var sent: [[FreshEpisode]] = []

    func requestAuthorization() async -> Bool { grantsPermission }
    func isAuthorized() async -> Bool { grantsPermission }
    func notify(_ episodes: [FreshEpisode]) async { sent.append(episodes) }
}
