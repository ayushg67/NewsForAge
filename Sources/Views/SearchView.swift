import SwiftUI

/// Searches across every feed the current bracket can access.
struct SearchView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(FeedStore.self) private var feedStore

    @State private var query = ""
    @State private var results: [Article] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    ProgressView("Searching worldwide…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if hasSearched && results.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "No \(settings.bracket.title.lowercased()) stories matched “\(query)”.")
                } else if results.isEmpty {
                    EmptyStateView(symbol: "globe",
                                   title: "Search the news",
                                   message: "Find stories across all your topics. Try “space”, “climate” or a country.")
                } else {
                    List(results) { article in
                        NavigationLink(value: article) {
                            ArticleRow(article: article)
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
                }
            }
            .navigationTitle("Search")
        }
        .searchable(text: $query, prompt: "Search worldwide news")
        .onSubmit(of: .search, runSearch)
        .onChange(of: query) { _, newValue in
            if newValue.isEmpty {
                results = []
                hasSearched = false
                searchTask?.cancel()
            }
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        searchTask = Task {
            isSearching = true
            let found = await feedStore.search(query, bracket: settings.bracket, language: settings.language, countryCode: settings.countryCode)
            if Task.isCancelled { return }
            results = found
            hasSearched = true
            isSearching = false
        }
    }
}
