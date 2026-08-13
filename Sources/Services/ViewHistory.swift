import Foundation
import Observation

/// Learns what the reader opens (categories + keywords) and ranks candidate
/// articles by that, powering the "Suggested for you" row. Persisted on-device.
@Observable
@MainActor
final class ViewHistory {
    private var categoryScore: [String: Double] = [:]
    private var keywordScore: [String: Double] = [:]
    private(set) var viewedIDs: [String] = []

    private let fileURL: URL
    private static let decay = 0.98

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("view-history.json")
        load()
    }

    var hasHistory: Bool { !categoryScore.isEmpty || !keywordScore.isEmpty }

    /// Records that the reader opened an article, reinforcing its category and words.
    func record(_ article: Article) {
        for key in categoryScore.keys { categoryScore[key]! *= Self.decay }
        for key in keywordScore.keys { keywordScore[key]! *= Self.decay }

        categoryScore[article.category.rawValue, default: 0] += 1
        for token in Self.tokens(in: article) { keywordScore[token, default: 0] += 1 }

        viewedIDs.removeAll { $0 == article.id }
        viewedIDs.insert(article.id, at: 0)
        if viewedIDs.count > 300 { viewedIDs = Array(viewedIDs.prefix(300)) }

        // Keep the keyword profile bounded.
        if keywordScore.count > 500 {
            keywordScore = Dictionary(uniqueKeysWithValues:
                keywordScore.sorted { $0.value > $1.value }.prefix(500).map { ($0.key, $0.value) })
        }
        save()
    }

    /// Best matches for the reader's taste, newest ties broken by recency.
    func suggestions(from candidates: [Article], limit: Int) -> [Article] {
        guard hasHistory else { return [] }
        let viewed = Set(viewedIDs)

        var seen = Set<String>()
        let scored: [(Article, Double)] = candidates
            .filter { !viewed.contains($0.id) && seen.insert($0.id).inserted }
            .map { ($0, score($0)) }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return (lhs.0.publishedAt ?? .distantPast) > (rhs.0.publishedAt ?? .distantPast)
            }
        return Array(scored.prefix(limit).map(\.0))
    }

    private func score(_ article: Article) -> Double {
        var total = (categoryScore[article.category.rawValue] ?? 0) * 2.0
        for token in Self.tokens(in: article) { total += keywordScore[token] ?? 0 }
        return total
    }

    // MARK: Tokenizing

    private static let stopwords: Set<String> = [
        "that", "this", "with", "from", "have", "been", "will", "your", "they",
        "them", "then", "than", "into", "over", "when", "what", "which", "would",
        "could", "should", "about", "after", "their", "there", "says", "said",
        "news", "also", "more", "most", "some", "such", "just", "like", "only",
        "other", "were", "still", "amid", "over", "says",
    ]

    private static func tokens(in article: Article) -> Set<String> {
        let text = (article.title + " " + article.summary).lowercased()
        let parts = text.split { !$0.isLetter }
        return Set(parts.map(String.init).filter { $0.count >= 4 && !stopwords.contains($0) })
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var categoryScore: [String: Double]
        var keywordScore: [String: Double]
        var viewedIDs: [String]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        categoryScore = s.categoryScore
        keywordScore = s.keywordScore
        viewedIDs = s.viewedIDs
    }

    private func save() {
        let s = Snapshot(categoryScore: categoryScore, keywordScore: keywordScore, viewedIDs: viewedIDs)
        guard let data = try? JSONEncoder().encode(s) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
