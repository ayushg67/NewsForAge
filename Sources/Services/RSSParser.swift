import Foundation

/// Streaming RSS 2.0 parser built on `XMLParser`. Extracts title, description,
/// link, publish date and a thumbnail (`media:thumbnail` or `media:content`).
final class RSSParser: NSObject, XMLParserDelegate {
    private let source: String
    private let category: Category

    private var articles: [Article] = []

    private var currentElement = ""
    private var insideItem = false
    private var title = ""
    private var itemDescription = ""
    private var link = ""
    private var pubDate = ""
    private var imageURL: String?
    private var itemSource = ""   // <source> element (Google News gives the real outlet)

    init(source: String, category: Category) {
        self.source = source
        self.category = category
    }

    func parse(_ data: Data) -> [Article] {
        articles.removeAll()
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        currentElement = elementName
        switch elementName {
        case "item":
            insideItem = true
            title = ""; itemDescription = ""; link = ""; pubDate = ""; imageURL = nil; itemSource = ""
        case "media:thumbnail", "media:content":
            // Prefer a wider image when several are offered.
            if let urlString = attributeDict["url"] {
                if imageURL == nil || (attributeDict["width"].flatMap(Int.init) ?? 0) >= 400 {
                    imageURL = urlString
                }
            }
        case "enclosure":
            if let type = attributeDict["type"], type.hasPrefix("image"),
               let urlString = attributeDict["url"], imageURL == nil {
                imageURL = urlString
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": title += string
        case "description": itemDescription += string
        case "link": link += string
        case "pubDate": pubDate += string
        case "source": itemSource += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard insideItem, let string = String(data: CDATABlock, encoding: .utf8) else { return }
        switch currentElement {
        case "title": title += string
        case "description": itemDescription += string
        case "link": link += string
        default: break
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        guard elementName == "item" else { return }
        insideItem = false

        let cleanedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: cleanedLink), !title.isEmpty else { return }

        // Google News gives "Headline - Outlet" titles plus a <source> element.
        let outlet = itemSource.trimmingCharacters(in: .whitespacesAndNewlines)
        var cleanTitle = title.cleanedHTML
        if !outlet.isEmpty, cleanTitle.hasSuffix(" - \(outlet)") {
            cleanTitle = String(cleanTitle.dropLast(outlet.count + 3))
        }

        let article = Article(
            title: cleanTitle,
            summary: itemDescription.cleanedHTML,
            link: url,
            imageURL: imageURL.flatMap { URL(string: $0) },
            source: outlet.isEmpty ? source : outlet,
            category: category,
            publishedAt: Self.dateFormatter.date(from: pubDate.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        articles.append(article)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()
}

private extension String {
    /// Strips HTML tags and decodes a few common entities for clean display.
    var cleanedHTML: String {
        var text = replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&quot;": "\"", "&#39;": "'", "&apos;": "'",
                        "&lt;": "<", "&gt;": ">", "&nbsp;": " ", "&#x27;": "'"]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
