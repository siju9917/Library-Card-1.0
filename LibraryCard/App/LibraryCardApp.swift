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
                Friendship.self,
                Organization.self,
                OrganizationMember.self,
                Showdown.self,
                ShowdownTeam.self,
                ShowdownParticipant.self,
                SessionPhoto.self,
                Wrapped.self,
                BarCheckIn.self,
                DirectMessage.self,
                Conversation.self,
                SwipeAction.self,
                Match.self,
                PreSwipe.self,
                DrinkGift.self,
                SOSAlert.self,
                DepartureNotification.self,
                PremiumSubscription.self,
                IDVerification.self
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

        NotificationService.shared.registerCategories()
        FunNotificationService.shared.registerCategories()
    }

    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool?

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(sessionManager)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .withGlobalAlerts()
            .preferredColorScheme(prefersDarkMode.map { $0 ? .dark : .light })
        }
        .modelContainer(modelContainer)
    }
}
