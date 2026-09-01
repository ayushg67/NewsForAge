import Foundation
import Observation
import WidgetKit

/// Tracks the reader's daily reading streak and totals, stored in a shared App
/// Group so the Home Screen widget can display the same data.
@Observable
@MainActor
final class ReadingStats {
    /// Shared between the app and the widget extension.
    static let appGroup = "group.com.NewsForAge.app"
    static let key = "newsforage.readingStats"

    private(set) var currentStreak = 0
    private(set) var longestStreak = 0
    private(set) var totalRead = 0
    private(set) var readTodayRaw = 0
    private var lastActiveDay = ""   // yyyy-MM-dd

    private var store: UserDefaults { UserDefaults(suiteName: Self.appGroup) ?? .standard }

    init() { load() }

    /// Current streak, or 0 if it has lapsed (nothing read yesterday or today).
    var streak: Int {
        (lastActiveDay == Self.today || lastActiveDay == Self.yesterday) ? currentStreak : 0
    }
    var readToday: Int { lastActiveDay == Self.today ? readTodayRaw : 0 }
    var activeToday: Bool { lastActiveDay == Self.today }

    /// Call when the reader opens an article.
    func recordRead() {
        let today = Self.today
        if lastActiveDay == today {
            readTodayRaw += 1
        } else if lastActiveDay == Self.yesterday {
            currentStreak += 1
            readTodayRaw = 1
            lastActiveDay = today
        } else {
            currentStreak = 1
            readTodayRaw = 1
            lastActiveDay = today
        }
        totalRead += 1
        longestStreak = max(longestStreak, currentStreak)
        save()
    }

    // MARK: Dates

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()
    static var today: String { formatter.string(from: Date()) }
    static var yesterday: String {
        formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    // MARK: Persistence (shared App Group)

    struct Snapshot: Codable {
        var currentStreak = 0, longestStreak = 0, totalRead = 0, readToday = 0
        var lastActiveDay = ""
    }

    private func load() {
        guard let data = store.data(forKey: Self.key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        currentStreak = s.currentStreak
        longestStreak = s.longestStreak
        totalRead = s.totalRead
        readTodayRaw = s.readToday
        lastActiveDay = s.lastActiveDay
    }

    private func save() {
        let s = Snapshot(currentStreak: currentStreak, longestStreak: longestStreak,
                         totalRead: totalRead, readToday: readTodayRaw, lastActiveDay: lastActiveDay)
        if let data = try? JSONEncoder().encode(s) { store.set(data, forKey: Self.key) }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
