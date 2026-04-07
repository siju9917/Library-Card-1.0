import SwiftUI
import SwiftData

@main
struct LibraryCardApp: App {
    let modelContainer: ModelContainer
    @StateObject private var sessionManager = SessionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        do {
            let schema = Schema([
                User.self,
                DrinkingSession.self,
                Drink.self,
                Venue.self,
                Transaction.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        // Register notification categories on launch
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(sessionManager)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}
