import SwiftUI

/// Shows the RSS summary with image and metadata, plus a button to read the
/// full story in an in-app web view. Can bookmark from here too.
struct ArticleDetailView: View {
    let article: Article
    @Environment(BookmarkStore.self) private var bookmarks
    @Environment(AppSettings.self) private var settings
    @Environment(SpeechService.self) private var speech
    @Environment(ViewHistory.self) private var history
    @State private var showWeb = false

    /// The text read aloud: headline followed by the summary.
    private var spokenText: String {
        article.summary.isEmpty ? article.title : "\(article.title). \(article.summary)"
    }

    private func speak() {
        speech.speak(spokenText,
                     languageCode: settings.language.speechLanguage,
                     voiceIdentifier: settings.voiceIdentifier)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color(.secondarySystemBackground))
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Label(article.category.title, systemImage: article.category.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.blue.opacity(0.15), in: Capsule())

                Text(article.title)
                    .font(.title2.bold())

                Text(article.relativeDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.body)
                }

                if settings.speechEnabled {
                    Button {
                        if speech.isSpeaking { speech.stop() }
                        else { speak() }
                    } label: {
                        Label(speech.isSpeaking ? "Stop listening" : "Listen",
                              systemImage: speech.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.top, 4)
                }

                Button {
                    speech.stop()
                    showWeb = true
                } label: {
                    Label("Read full story", systemImage: "safari")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(article.source)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    bookmarks.toggle(article)
                } label: {
                    Image(systemName: bookmarks.isSaved(article) ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .sheet(isPresented: $showWeb) {
            SafariWebView(url: article.link)
                .ignoresSafeArea()
        }
        .onAppear {
            history.record(article)
            if settings.speechEnabled { speak() }
        }
        .onDisappear { speech.stop() }
    }
}
