import AVFoundation
import XCTest
@testable import Podcasts_Bin

@MainActor
final class ListeningStatsTests: XCTestCase {
    private static var retainedPlayers: [AVPlayer] = []
    private var defaults: UserDefaults!
    private var suite: String!
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        return calendar
    }()

    override func setUp() async throws {
        suite = "ListeningStatsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    private func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func stats() -> ListeningStats {
        var stats = ListeningStats(defaults: defaults)
        stats.calendar = calendar
        return stats
    }

    func test_record_addsUpPerDayAndInTotal() {
        let stats = stats()
        stats.record(60, at: date(1))
        stats.record(30, at: date(1, hour: 23))
        stats.record(120, at: date(2, hour: 0))

        XCTAssertEqual(stats.seconds(on: date(1)), 90)
        XCTAssertEqual(stats.seconds(on: date(2)), 120)
        XCTAssertEqual(stats.totalSeconds, 210)
    }

    func test_record_ignoresInvalidDurations() {
        let stats = stats()
        stats.record(-5, at: date(1))
        stats.record(.nan, at: date(1))
        stats.record(.infinity, at: date(1))
        XCTAssertEqual(stats.totalSeconds, 0)
    }

    func test_lastDays_fillsGapsWithZeroOldestFirst() {
        let stats = stats()
        stats.record(600, at: date(1))
        stats.record(300, at: date(7))
        stats.record(999, at: date(8))

        let week = stats.lastDays(7, endingOn: date(7))

        XCTAssertEqual(week.map(\.seconds), [600, 0, 0, 0, 0, 0, 300])
        XCTAssertEqual(week.first?.day, calendar.startOfDay(for: date(1)))
    }

    // MARK: - PlaybackController

    private func makePlayer() throws -> PlaybackController {
        let data = try JSONSerialization.data(withJSONObject: [
            "title": "Episode", "subtitle": "", "pubDate": 0, "description": "", "author": "Author",
            "streamUrl": "file:///private/tmp/listening-stats-test.wav"
        ])
        let episode = EpisodeViewModel(episode: try JSONDecoder().decode(Episode.self, from: data))
        let avPlayer = AVPlayer()
        Self.retainedPlayers.append(avPlayer)
        let sut = PlaybackController(player: avPlayer, defaults: defaults, systemPlaybackEnabled: false,
                                     localFile: { _ in nil }, saveHistory: { _ in })
        sut.load(episode, queue: [episode])
        return sut
    }

    func test_playback_countsWallClockTimeBetweenTicks() throws {
        let sut = try makePlayer()
        defer { sut.close() }
        let start = Date()

        sut.noteListeningTick(at: start)
        sut.noteListeningTick(at: start.addingTimeInterval(1))
        sut.noteListeningTick(at: start.addingTimeInterval(2.5))

        XCTAssertEqual(sut.listeningStats.totalSeconds, 2.5, accuracy: 0.001)
    }

    func test_playback_ignoresLongGapsAndTimeWhilePaused() throws {
        let sut = try makePlayer()
        defer { sut.close() }
        let start = Date()

        sut.noteListeningTick(at: start)
        sut.noteListeningTick(at: start.addingTimeInterval(60))   // e.g. the app was suspended
        sut.pause()
        sut.noteListeningTick(at: start.addingTimeInterval(61))
        sut.noteListeningTick(at: start.addingTimeInterval(62))

        XCTAssertEqual(sut.listeningStats.totalSeconds, 0)
    }

    func test_playback_seekingRestartsTheCount() throws {
        let sut = try makePlayer()
        defer { sut.close() }
        let start = Date()

        sut.noteListeningTick(at: start)
        sut.seek(to: 300)
        sut.noteListeningTick(at: start.addingTimeInterval(1))

        XCTAssertEqual(sut.listeningStats.totalSeconds, 0)
    }
}
