import SwiftUI

/// A summary of the reader's streak and totals, shown as a sheet from the feed.
struct ReadingStatsView: View {
    @Environment(ReadingStats.self) private var stats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 64))
                    Text("\(stats.streak)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(stats.streak == 1 ? "day streak" : "day streak")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(stats.activeToday
                         ? "You've read today — keep it going!"
                         : "Read a story today to keep your streak alive.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                HStack(spacing: 12) {
                    StatTile(value: stats.readToday, label: "Today", symbol: "sun.max.fill")
                    StatTile(value: stats.longestStreak, label: "Best streak", symbol: "trophy.fill")
                    StatTile(value: stats.totalRead, label: "Total read", symbol: "book.fill")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Your reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct StatTile: View {
    let value: Int
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.blue)
            Text("\(value)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
