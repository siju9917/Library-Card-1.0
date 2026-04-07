import SwiftUI
import SwiftData

@main
struct LibraryCardApp: App {
    let modelContainer: ModelContainer

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionManager())
        }
        .modelContainer(modelContainer)
    }
}
