import Foundation

/// One RSS endpoint belonging to a category.
struct FeedSource {
    let source: String
    let url: URL
}

/// Maps each category to its verified, working RSS feeds.
///
/// Reuters discontinued its public RSS feeds, so The Guardian stands in as the
/// second reputable worldwide source alongside the BBC.
enum Feeds {
    static func sources(for category: Category) -> [FeedSource] {
        rawMap[category]?.compactMap { source, string in
            URL(string: string).map { FeedSource(source: source, url: $0) }
        } ?? []
    }

    private static let rawMap: [Category: [(String, String)]] = [
        .world: [
            ("BBC", "https://feeds.bbci.co.uk/news/world/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/world/rss"),
        ],
        .science: [
            ("BBC", "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/science/rss"),
        ],
        .technology: [
            ("BBC", "https://feeds.bbci.co.uk/news/technology/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/technology/rss"),
        ],
        .environment: [
            ("The Guardian", "https://www.theguardian.com/environment/rss"),
            ("BBC", "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml"),
        ],
        .sports: [
            ("BBC", "https://feeds.bbci.co.uk/sport/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/sport/rss"),
        ],
        .animals: [
            ("The Guardian", "https://www.theguardian.com/environment/wildlife/rss"),
        ],
        .space: [
            ("The Guardian", "https://www.theguardian.com/science/space/rss"),
        ],
        .politics: [
            ("BBC", "https://feeds.bbci.co.uk/news/politics/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/politics/rss"),
        ],
        .business: [
            ("BBC", "https://feeds.bbci.co.uk/news/business/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/business/rss"),
        ],
        .crime: [
            ("BBC", "https://feeds.bbci.co.uk/news/uk/rss.xml"),
            ("The Guardian", "https://www.theguardian.com/law/rss"),
        ],
    ]
}
