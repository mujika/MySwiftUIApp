import SwiftUI

@main
struct MySwiftUIAppApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.hasCompletedOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .environment(store)
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.6), value: store.hasCompletedOnboarding)
        }
    }
}
