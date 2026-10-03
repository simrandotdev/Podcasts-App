import Foundation

/// Wall-clock listening time, kept per calendar day in UserDefaults.
struct ListeningStats {
    static let byDayKey = "listeningSecondsByDay"

    let defaults: UserDefaults
    var calendar = Calendar.current

    /// "yyyy-MM-dd" in the user's time zone, so a day matches what the user calls today.
    private func dayKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private var byDay: [String: Double] {
        (defaults.dictionary(forKey: Self.byDayKey) as? [String: Double]) ?? [:]
    }

    func record(_ seconds: Double, at date: Date = Date()) {
        guard seconds.isFinite, seconds > 0 else { return }
        var days = byDay
        days[dayKey(for: date), default: 0] += seconds
        defaults.set(days, forKey: Self.byDayKey)
    }

    var totalSeconds: Double { byDay.values.reduce(0, +) }

    func seconds(on date: Date) -> Double { byDay[dayKey(for: date)] ?? 0 }

    /// The last `count` days ending with `date`'s day, oldest first; days without listening are 0.
    func lastDays(_ count: Int, endingOn date: Date = Date()) -> [(day: Date, seconds: Double)] {
        let today = calendar.startOfDay(for: date)
        let days = byDay
        return (0..<count).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (day, days[dayKey(for: day)] ?? 0)
        }
    }
}
