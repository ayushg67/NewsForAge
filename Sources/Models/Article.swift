import Foundation

struct Article: Identifiable, Codable, Hashable {
    let id: String          // stable id derived from the article link
    let title: String
    let summary: String
    let link: URL
    let imageURL: URL?
    let source: String      // e.g. "BBC", "The Guardian"
    let category: Category
    let publishedAt: Date?

    init(title: String,
         summary: String,
         link: URL,
         imageURL: URL?,
         source: String,
         category: Category,
         publishedAt: Date?) {
        self.id = link.absoluteString
        self.title = title
        self.summary = summary
        self.link = link
        self.imageURL = imageURL
        self.source = source
        self.category = category
        self.publishedAt = publishedAt
    }

    var relativeDate: String {
        guard let publishedAt else { return source }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "\(source) · \(formatter.localizedString(for: publishedAt, relativeTo: Date()))"
    }
}
