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

    // Keyed by "language.category" so each language keeps its own cached feed.
    private(set) var articlesByKey: [String: [Article]] = [:]
    private(set) var stateByKey: [String: LoadState] = [:]

    private let service = NewsService()
    private let cacheURL: URL

    private func key(_ category: Category, _ language: Language, _ countryCode: String?) -> String {
        "\(language.rawValue).\(countryCode ?? "ww").\(category.rawValue)"
    }

    init() {
        // Application Support (not Caches) so iOS never purges the offline copy.
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheURL = dir.appendingPathComponent("feed-cache.json")
        loadCache()

        // One-time migration of any cache written to the old Caches location,
        // which was keyed by bare category. Re-key it under the English language.
        let old = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("feed-cache.json")
        if articlesByKey.isEmpty,
           let data = try? Data(contentsOf: old),
           let decoded = try? JSONDecoder().decode([String: [Article]].self, from: data) {
            for (category, value) in decoded where Category(rawValue: category) != nil {
                articlesByKey["\(Language.english.rawValue).\(category)"] = value
            }
            saveCache()
        }
    }

    func articles(for category: Category, language: Language, countryCode: String?) -> [Article] {
        articlesByKey[key(category, language, countryCode)] ?? []
    }

    /// All cached articles across the given categories for the current edition,
    /// used as candidates for suggestions.
    func cachedArticles(in categories: [Category], language: Language, countryCode: String?) -> [Article] {
        categories.flatMap { articles(for: $0, language: language, countryCode: countryCode) }
    }

    func state(for category: Category, language: Language, countryCode: String?) -> LoadState {
        stateByKey[key(category, language, countryCode)] ?? .idle
    }

    /// Loads a category only if it hasn't been loaded yet this session.
    func loadIfNeeded(_ category: Category, language: Language, countryCode: String?) async {
        let state = state(for: category, language: language, countryCode: countryCode)
        if case .loaded = state { return }
        if case .loading = state { return }
        await refresh(category, language: language, countryCode: countryCode)
    }

    func refresh(_ category: Category, language: Language, countryCode: String?) async {
        let k = key(category, language, countryCode)
        stateByKey[k] = .loading
        let fetched = await service.articles(for: category, language: language, countryCode: countryCode)
        if fetched.isEmpty && !articles(for: category, language: language, countryCode: countryCode).isEmpty {
            // Keep the cached copy; surface a soft failure.
            stateByKey[k] = .failed("Couldn't refresh — showing saved stories.")
        } else if fetched.isEmpty {
            stateByKey[k] = .failed("No internet connection or no stories available.")
        } else {
            articlesByKey[k] = fetched
            stateByKey[k] = .loaded
            saveCache()
        }
    }

    /// Searches across every feed the bracket is allowed to see, in the current language/country.
    func search(_ query: String, bracket: AgeBracket, language: Language, countryCode: String?) async -> [Article] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let categories = bracket.allowedCategories
        let collected = await withTaskGroup(of: [Article].self) { group in
            for category in categories {
                group.addTask { [service] in
                    await service.articles(for: category, language: language, countryCode: countryCode)
                }
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
        articlesByKey = decoded
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(articlesByKey) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
