import SwiftUI

/// The main news feed: a category selector across the top and a scrollable list
/// of articles for the selected category, with pull-to-refresh.
struct FeedView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(FeedStore.self) private var feedStore
    @Environment(ViewHistory.self) private var history

    @State private var selection: Category?

    private var categories: [Category] { settings.bracket.allowedCategories }

    /// The category actually shown: the user's pick, or the bracket's first.
    private var selected: Category { selection ?? categories.first ?? .science }

    private var language: Language { settings.language }
    private var countryCode: String? { settings.countryCode }

    private var focusBanner: String? {
        countryCode.map { "📍 News about \(Country($0).name(in: language))" }
    }

    /// Personalized picks from other categories, shown on the landing feed.
    private var suggestions: [Article] {
        guard selected == categories.first, history.hasHistory else { return [] }
        let others = categories.filter { $0 != selected }
        let candidates = feedStore.cachedArticles(in: others, language: language, countryCode: countryCode)
        return history.suggestions(from: candidates, limit: 10)
    }

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
        // Re-fires when the category, language, or country changes.
        .task(id: "\(language.rawValue).\(countryCode ?? "ww").\(selected.rawValue)") {
            await feedStore.loadIfNeeded(selected, language: language, countryCode: countryCode)
        }
        // Warm other categories so suggestions have material (only once there's history).
        // hasHistory is in the id so this re-fires the moment the first view is recorded.
        .task(id: "prefetch.\(language.rawValue).\(countryCode ?? "ww").\(history.hasHistory)") {
            guard history.hasHistory else { return }
            await withTaskGroup(of: Void.self) { group in
                for category in categories where category != selected {
                    group.addTask { await feedStore.loadIfNeeded(category, language: language, countryCode: countryCode) }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let articles = feedStore.articles(for: selected, language: language, countryCode: countryCode)
        let state = feedStore.state(for: selected, language: language, countryCode: countryCode)

        if articles.isEmpty {
            switch state {
            case .loading, .idle:
                LoadingList()
            case .failed(let message):
                EmptyStateView(symbol: "wifi.slash", title: "Nothing to show", message: message) {
                    Task { await feedStore.refresh(selected, language: language, countryCode: countryCode) }
                }
            case .loaded:
                EmptyStateView(symbol: "tray", title: "No stories", message: "This category has no stories right now.") {
                    Task { await feedStore.refresh(selected, language: language, countryCode: countryCode) }
                }
            }
        } else {
            List {
                if let focusBanner {
                    Text(focusBanner)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.blue)
                        .listRowSeparator(.hidden)
                }
                let picks = suggestions
                if !picks.isEmpty {
                    Section {
                        SuggestionsRow(articles: picks)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    } header: {
                        Label(L.t("Suggested for you", language), systemImage: "sparkles")
                    }
                }
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
            .refreshable { await feedStore.refresh(selected, language: language, countryCode: countryCode) }
            .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
        }
    }
}

/// Horizontal carousel of personalized article suggestions.
struct SuggestionsRow: View {
    let articles: [Article]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(articles) { article in
                    NavigationLink(value: article) {
                        SuggestionCard(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct SuggestionCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: article.imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 200, height: 120)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Label(article.category.title, systemImage: article.category.symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.blue)
            Text(article.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Text(article.source)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 200, alignment: .leading)
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
