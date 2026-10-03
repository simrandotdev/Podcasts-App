import Foundation

/// A GitHub-style year of listening: one column per week, one row per weekday.
struct ListeningHeatmap {
    struct Day {
        let date: Date
        let seconds: Double

        var minutes: Int { Int(seconds / 60) }
        var level: Int { ListeningHeatmap.level(forMinutes: minutes) }
    }

    /// Week columns, oldest first. Each has 7 slots in calendar order (starting on the locale's
    /// first weekday); slots after today are nil.
    let weeks: [[Day?]]
    let calendar: Calendar

    /// Lower bounds, in minutes, of levels 1–4. Fixed bands keep a colour's meaning stable over time.
    static let levelThresholds = [1, 15, 30, 60]

    static func level(forMinutes minutes: Int) -> Int {
        levelThresholds.lastIndex(where: { minutes >= $0 }).map { $0 + 1 } ?? 0
    }

    init(stats: ListeningStats, endingOn date: Date = Date(), weekCount: Int = 53) {
        let calendar = stats.calendar
        self.calendar = calendar
        let today = calendar.startOfDay(for: date)
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let firstDay = calendar.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: thisWeek) ?? thisWeek
        let dayCount = (calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0) + 1

        let days: [Day] = stats.lastDays(dayCount, endingOn: today).map { item in
            Day(date: item.day, seconds: item.seconds)
        }
        var weeks: [[Day?]] = []
        for week in 0..<weekCount {
            var column: [Day?] = []
            for index in week * 7..<week * 7 + 7 {
                column.append(index < days.count ? days[index] : nil)
            }
            weeks.append(column)
        }
        self.weeks = weeks
    }

    private var allDays: [Day] { weeks.flatMap { $0.compactMap { $0 } } }

    var totalSeconds: Double { allDays.reduce(0) { $0 + $1.seconds } }

    /// Days with at least a minute of listening.
    var activeDays: Int { allDays.filter { $0.level > 0 }.count }

    var longestStreak: Int {
        var longest = 0, current = 0
        for day in allDays {
            current = day.level > 0 ? current + 1 : 0
            longest = max(longest, current)
        }
        return longest
    }

    /// Consecutive active days up to today. Today doesn't break the streak until it's over.
    var currentStreak: Int {
        var days = Array(allDays.reversed())
        if let today = days.first, today.level == 0 { days.removeFirst() }
        return days.prefix { $0.level > 0 }.count
    }
}
