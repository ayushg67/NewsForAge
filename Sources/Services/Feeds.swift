import Foundation

/// One RSS endpoint belonging to a category.
struct FeedSource {
    let source: String
    let url: URL
}

/// Resolves the RSS feeds for a (category, language) pair.
///
/// Each language carries its own feed table (see `Language`). Rich languages map
/// every category to a dedicated section; single-feed languages define only the
/// `.world` slot, so any other category falls back to it.
enum Feeds {
    static func sources(for category: Category, language: Language) -> [FeedSource] {
        let feeds = language.feeds
        let entries = feeds[category] ?? feeds[.world] ?? []
        return entries.compactMap { source, string in
            URL(string: string).map { FeedSource(source: source, url: $0) }
        }
    }
}
