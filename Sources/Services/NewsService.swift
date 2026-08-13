import Foundation

/// Fetches and parses RSS feeds. Stateless and reusable across the app.
struct NewsService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    /// Loads a category for the given language and optional target country.
    ///
    /// With no country, uses the language's national outlet feeds. With a
    /// country, queries Google News for that country in the reader's language;
    /// if that yields nothing, falls back to the national outlet feeds.
    func articles(for category: Category, language: Language, countryCode: String?) async -> [Article] {
        if let countryCode {
            let country = Country(countryCode)
            let source = Self.googleNewsSource(country: country, category: category, language: language)
            let byCountry = Self.merge(await fetch(source, category: category))
            if !byCountry.isEmpty { return byCountry }
            // Fall through to the national outlet if the country search is empty.
        }

        let sources = Feeds.sources(for: category, language: language)
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

    /// Builds a Google News RSS search for a country's news in the reader's language.
    static func googleNewsSource(country: Country, category: Category, language: Language) -> FeedSource {
        let name = country.name(in: language)
        let keyword = category.googleKeyword
        let query = keyword.isEmpty ? name : "\(name) \(keyword)"

        var components = URLComponents(string: "https://news.google.com/rss/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "hl", value: language.googleHL),
            URLQueryItem(name: "gl", value: language.googleGL),
            URLQueryItem(name: "ceid", value: "\(language.googleGL):\(language.googleHL)"),
        ]
        return FeedSource(source: "Google News", url: components.url!)
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
