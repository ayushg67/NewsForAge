import SwiftUI

/// Routes between onboarding and the main app based on whether an age is set.
struct RootView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Group {
            if settings.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: settings.hasOnboarded)
    }
}
