import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("News", systemImage: "newspaper") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            SavedView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
