import SwiftUI

struct SavedView: View {
    @Environment(BookmarkStore.self) private var bookmarks

    var body: some View {
        NavigationStack {
            Group {
                if bookmarks.articles.isEmpty {
                    EmptyStateView(symbol: "bookmark",
                                   title: "No saved stories",
                                   message: "Tap the bookmark on any article to save it here for later.")
                } else {
                    List {
                        ForEach(bookmarks.articles) { article in
                            NavigationLink(value: article) {
                                ArticleRow(article: article)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { bookmarks.articles[$0] }.forEach(bookmarks.toggle)
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
                }
            }
            .navigationTitle("Saved")
        }
    }
}
