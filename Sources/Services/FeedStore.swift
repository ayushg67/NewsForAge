import Foundation
import Observation

/// Loads, caches and searches news for the current age bracket.
///
/// The most recent successful fetch for each category is written to disk so the
/// app can show content instantly on launch and briefly while offline.
@Observable
@MainActor
final class FeedStore {
    enum LoadState: Equatable {
        case idle, loading, loaded, failed(String)
    }

    private(set) var articlesByCategory: [Category: [Article]] = [:]
    private(set) var state: [Category: LoadState] = [:]

    private let service = NewsService()
    private let cacheURL: URL

    init() {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheURL = dir.appendingPathComponent("feed-cache.json")
        loadCache()
    }

    func articles(for category: Category) -> [Article] {
        articlesByCategory[category] ?? []
    }

    func state(for category: Category) -> LoadState {
        state[category] ?? .idle
    }

    /// Loads a category only if it hasn't been loaded yet this session.
    func loadIfNeeded(_ category: Category) async {
        if case .loaded = state(for: category) { return }
        if case .loading = state(for: category) { return }
        await refresh(category)
    }

    func refresh(_ category: Category) async {
        state[category] = .loading
        let fetched = await service.articles(for: category)
        if fetched.isEmpty && !articles(for: category).isEmpty {
            // Keep the cached copy; surface a soft failure.
            state[category] = .failed("Couldn't refresh — showing saved stories.")
        } else if fetched.isEmpty {
            state[category] = .failed("No internet connection or no stories available.")
        } else {
            articlesByCategory[category] = fetched
            state[category] = .loaded
            saveCache()
        }
    }

    /// Searches across every feed the bracket is allowed to see.
    func search(_ query: String, bracket: AgeBracket) async -> [Article] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let categories = bracket.allowedCategories
        let collected = await withTaskGroup(of: [Article].self) { group in
            for category in categories {
                group.addTask { [service] in await service.articles(for: category) }
            }
            var all: [Article] = []
            for await batch in group { all.append(contentsOf: batch) }
            return all
        }

        let merged = NewsService.merge(collected)
        let needle = trimmed.lowercased()
        return merged.filter {
            $0.title.lowercased().contains(needle) || $0.summary.lowercased().contains(needle)
        }
    }

    // MARK: Disk cache

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode([String: [Article]].self, from: data) else { return }
        for (key, value) in decoded {
            if let category = Category(rawValue: key) { articlesByCategory[category] = value }
        }
    }

    private func saveCache() {
        let mapped = Dictionary(uniqueKeysWithValues:
            articlesByCategory.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(mapped) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
