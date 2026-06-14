import Foundation

/// Fetches and parses RSS feeds. Stateless and reusable across the app.
struct NewsService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    /// Loads every feed for a category concurrently and merges the results,
    /// newest first, de-duplicated by link.
    func articles(for category: Category) async -> [Article] {
        let sources = Feeds.sources(for: category)

        let collected = await withTaskGroup(of: [Article].self) { group in
            for source in sources {
                group.addTask { await fetch(source, category: category) }
            }
            var all: [Article] = []
            for await batch in group { all.append(contentsOf: batch) }
            return all
        }

        return Self.merge(collected)
    }

    private func fetch(_ feed: FeedSource, category: Category) async -> [Article] {
        var request = URLRequest(url: feed.url)
        request.setValue("Mozilla/5.0 (NewsForAge)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            return RSSParser(source: feed.source, category: category).parse(data)
        } catch {
            return []
        }
    }

    /// De-duplicates by id and sorts newest first.
    static func merge(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        let unique = articles.filter { seen.insert($0.id).inserted }
        return unique.sorted {
            ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }
    }
}
