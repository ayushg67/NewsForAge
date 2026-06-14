import Foundation
import Observation

/// Persisted reader profile: the entered age and the bracket it implies.
@Observable
final class AppSettings {
    private static let ageKey = "newsforage.age"
    private static let speechKey = "newsforage.speechEnabled"

    var age: Int? {
        didSet {
            if let age { UserDefaults.standard.set(age, forKey: Self.ageKey) }
            else { UserDefaults.standard.removeObject(forKey: Self.ageKey) }
        }
    }

    /// When on, opening an article reads it aloud.
    var speechEnabled: Bool {
        didSet { UserDefaults.standard.set(speechEnabled, forKey: Self.speechKey) }
    }

    init() {
        let stored = UserDefaults.standard.integer(forKey: Self.ageKey)
        age = stored > 0 ? stored : nil
        // Default to on for first launch; respect a stored choice thereafter.
        speechEnabled = UserDefaults.standard.object(forKey: Self.speechKey) as? Bool ?? true
    }

    var hasOnboarded: Bool { age != nil }

    var bracket: AgeBracket { AgeBracket(age: age ?? 18) }

    func reset() { age = nil }
}

/// Bookmarked articles, persisted to disk as JSON.
@Observable
final class BookmarkStore {
    private(set) var articles: [Article] = []
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("bookmarks.json")
        load()
    }

    func isSaved(_ article: Article) -> Bool {
        articles.contains { $0.id == article.id }
    }

    func toggle(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles.remove(at: index)
        } else {
            articles.insert(article, at: 0)
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Article].self, from: data) else { return }
        articles = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
