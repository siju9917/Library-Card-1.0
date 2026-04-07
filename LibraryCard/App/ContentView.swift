import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case session = "Session"
        case stats = "Stats"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .session: return "play.circle.fill"
            case .stats: return "chart.bar.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            SessionView()
                .tabItem {
                    Label(Tab.session.rawValue, systemImage: Tab.session.icon)
                }
                .tag(Tab.session)

            StatsView()
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(AppColor.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
        .modelContainer(for: [
            User.self,
            DrinkingSession.self,
            Drink.self,
            Venue.self,
            Transaction.self
        ], inMemory: true)
}
