import SwiftUI
import Observation

@main
struct FindYourTypeApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            VibeMateFlowView()
                .environment(store)
        }
    }
}

/// Two tabs: Quiz / Explore
@Observable
final class AppRouter {
    enum Tab: Hashable { case quiz, explore }
    var tab: Tab = .quiz
}

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        if let error = store.loadError {
            ContentUnavailableView("Data failed to load", systemImage: "exclamationmark.triangle",
                                   description: Text(error))
        } else {
            TabView(selection: $router.tab) {
                QuizFlowView()
                    .tabItem { Label("Quiz", systemImage: "heart.text.square") }
                    .tag(AppRouter.Tab.quiz)
                ExploreView()
                    .tabItem { Label("Explore", systemImage: "chart.bar.xaxis") }
                    .tag(AppRouter.Tab.explore)
            }
            .tint(.pink)
        }
    }
}
