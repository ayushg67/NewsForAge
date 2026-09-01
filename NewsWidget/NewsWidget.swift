import WidgetKit
import SwiftUI

// Mirrors ReadingStats.Snapshot in the app; shared via the App Group.
private struct StatsSnapshot: Codable {
    var currentStreak = 0, longestStreak = 0, totalRead = 0, readToday = 0
    var lastActiveDay = ""
}

private enum Shared {
    static let appGroup = "group.com.NewsForAge.app"
    static let key = "newsforage.readingStats"

    static func load() -> StatsSnapshot {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(StatsSnapshot.self, from: data) else {
            return StatsSnapshot()
        }
        return snapshot
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()
    static func day(offset: Int = 0) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let longest: Int
    let total: Int
    let readToday: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 5, longest: 12, total: 87, readToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // Refresh just after midnight so a lapsed streak resets on screen.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [currentEntry()], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> StreakEntry {
        let s = Shared.load()
        let alive = s.lastActiveDay == Shared.day() || s.lastActiveDay == Shared.day(offset: -1)
        return StreakEntry(date: Date(),
                           streak: alive ? s.currentStreak : 0,
                           longest: s.longestStreak,
                           total: s.totalRead,
                           readToday: s.lastActiveDay == Shared.day())
    }
}

struct NewsWidgetEntryView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🔥 \(entry.streak)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(entry.streak == 1 ? "day streak" : "day streak")
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(entry.readToday ? "Read today ✓" : "Read to keep it up")
                .font(.caption2)
                .foregroundStyle(entry.readToday ? .green : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("🔥 \(entry.streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("day streak")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(entry.readToday ? "Read today ✓" : "Read to keep it up")
                    .font(.caption)
                    .foregroundStyle(entry.readToday ? .green : .orange)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                stat("trophy.fill", entry.longest, "Best")
                stat("book.fill", entry.total, "Read")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stat(_ symbol: String, _ value: Int, _ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(.blue).font(.caption)
            Text("\(value)").font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct NewsWidget: Widget {
    let kind = "NewsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NewsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reading Streak")
        .description("Keep your News Sphere reading streak going.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NewsWidgetBundle: WidgetBundle {
    var body: some Widget { NewsWidget() }
}
