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

    // MARK: - Heatmap

    func test_heatmapLevel_usesFixedMinuteBands() {
        XCTAssertEqual([0, 1, 14, 15, 29, 30, 59, 60, 240].map(ListeningHeatmap.level(forMinutes:)),
                       [0, 1, 1, 2, 2, 3, 3, 4, 4])
    }

    func test_heatmap_alignsWeeksToTheCalendarAndEndsToday() {
        var calendar = self.calendar
        calendar.firstWeekday = 1   // Sunday
        var stats = stats()
        stats.calendar = calendar
        let today = date(15)        // Thursday, October 15, 2026
        stats.record(600, at: today)

        let heatmap = ListeningHeatmap(stats: stats, endingOn: today, weekCount: 3)

        XCTAssertEqual(heatmap.weeks.count, 3)
        XCTAssertTrue(heatmap.weeks.allSatisfy { $0.count == 7 })
        let firstDay = heatmap.weeks[0][0]?.date
        XCTAssertEqual(firstDay.map { calendar.component(.weekday, from: $0) }, 1, "Columns start on Sunday")
        XCTAssertEqual(firstDay, calendar.date(from: DateComponents(year: 2026, month: 9, day: 27)),
                       "Three weeks ending the week of Oct 11 start on Sunday, Sep 27")
        let lastWeek = heatmap.weeks[2]
        XCTAssertEqual(lastWeek[4]?.date, calendar.startOfDay(for: today), "Thursday is the fifth row")
        XCTAssertEqual(lastWeek[4]?.minutes, 10)
        XCTAssertNil(lastWeek[5], "Days after today are empty")
        XCTAssertNil(lastWeek[6])
    }

    func test_heatmap_countsActiveDaysAndStreaks() {
        let stats = stats()
        for day in [1, 2, 3, 6, 7, 8, 9] { stats.record(120, at: date(day)) }
        stats.record(20, at: date(5))   // under a minute: not an active day

        // Today (the 10th) has no listening yet, so the current streak runs through yesterday.
        let heatmap = ListeningHeatmap(stats: stats, endingOn: date(10), weekCount: 4)

        XCTAssertEqual(heatmap.activeDays, 7)
        XCTAssertEqual(heatmap.longestStreak, 4)
        XCTAssertEqual(heatmap.currentStreak, 4)
        XCTAssertEqual(heatmap.totalSeconds, 7 * 120 + 20)
    }

    func test_heatmap_currentStreakIsZeroAfterAMissedDay() {
        let stats = stats()
        stats.record(120, at: date(7))
        let heatmap = ListeningHeatmap(stats: stats, endingOn: date(9), weekCount: 2)
        XCTAssertEqual(heatmap.currentStreak, 0)
        XCTAssertEqual(heatmap.longestStreak, 1)
    }

    // MARK: - PlaybackManager

    private func makePlayer() throws -> PlaybackManager {
        let data = try JSONSerialization.data(withJSONObject: [
            "title": "Episode", "subtitle": "", "pubDate": 0, "description": "", "author": "Author",
            "streamUrl": "file:///private/tmp/listening-stats-test.wav"
        ])
        let episode = try JSONDecoder().decode(Episode.self, from: data)
        let avPlayer = AVPlayer()
        Self.retainedPlayers.append(avPlayer)
        let sut = PlaybackManager(player: avPlayer, defaults: defaults, systemPlaybackEnabled: false,
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
