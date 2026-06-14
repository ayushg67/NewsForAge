import SwiftUI

/// The main news feed: a category selector across the top and a scrollable list
/// of articles for the selected category, with pull-to-refresh.
struct FeedView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(FeedStore.self) private var feedStore

    @State private var selection: Category?

    private var categories: [Category] { settings.bracket.allowedCategories }

    /// The category actually shown: the user's pick, or the bracket's first.
    private var selected: Category { selection ?? categories.first ?? .science }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryBar(categories: categories,
                            selected: Binding(get: { selected },
                                              set: { selection = $0 }))
                Divider()
                content
            }
            .navigationTitle("Newsphere")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: selected) {
            await feedStore.loadIfNeeded(selected)
        }
    }

    @ViewBuilder
    private var content: some View {
        let articles = feedStore.articles(for: selected)
        let state = feedStore.state(for: selected)

        if articles.isEmpty {
            switch state {
            case .loading, .idle:
                LoadingList()
            case .failed(let message):
                EmptyStateView(symbol: "wifi.slash", title: "Nothing to show", message: message) {
                    Task { await feedStore.refresh(selected) }
                }
            case .loaded:
                EmptyStateView(symbol: "tray", title: "No stories", message: "This category has no stories right now.") {
                    Task { await feedStore.refresh(selected) }
                }
            }
        } else {
            List {
                if case .failed(let message) = state {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                }
                ForEach(articles) { article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await feedStore.refresh(selected) }
            .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
        }
    }
}

/// Horizontally scrolling pill selector for categories.
struct CategoryBar: View {
    let categories: [Category]
    @Binding var selected: Category

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    let isSelected = category == selected
                    Button {
                        selected = category
                    } label: {
                        Label(category.title, systemImage: category.symbol)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.blue : Color(.secondarySystemBackground),
                                        in: Capsule())
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
