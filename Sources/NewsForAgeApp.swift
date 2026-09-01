import SwiftUI

@main
struct NewsForAgeApp: App {
    @State private var settings = AppSettings()
    @State private var feedStore = FeedStore()
    @State private var bookmarks = BookmarkStore()
    @State private var speech = SpeechService()
    @State private var history = ViewHistory()
    @State private var stats = ReadingStats()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(feedStore)
                .environment(bookmarks)
                .environment(speech)
                .environment(history)
                .environment(stats)
                .tint(.blue)
        }
    }
}
