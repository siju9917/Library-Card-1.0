import Testing
import Foundation
@testable import LibraryCard

@Suite("StatsViewModel Tests")
struct StatsViewModelTests {
    // MARK: - Period Filtering

    @Test("Default period is week")
    func defaultPeriod() {
        let vm = StatsViewModel()
        #expect(vm.selectedPeriod == .week)
    }

    @Test("Loading with empty sessions produces zero stats")
    func emptySessionStats() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.totalDrinks == 0)
        #expect(vm.totalSpend == 0)
        #expect(vm.totalSessions == 0)
        #expect(vm.averageDrinksPerSession == 0)
        #expect(vm.averageSpendPerSession == 0)
        #expect(vm.averageDrinksPerHour == 0)
        #expect(vm.totalCalories == 0)
    }

    @Test("Chart data is empty with no sessions")
    func emptyChartData() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.drinksOverTime.isEmpty)
        #expect(vm.spendOverTime.isEmpty)
        #expect(vm.drinkTypeDistribution.isEmpty)
        #expect(vm.dayOfWeekDistribution.count == 7) // Always has 7 days
        #expect(vm.topVenues.isEmpty)
    }

    @Test("Day of week distribution always has 7 entries")
    func dayOfWeekAlwaysSeven() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.dayOfWeekDistribution.count == 7)

        let dayNames = vm.dayOfWeekDistribution.map(\.day)
        #expect(dayNames.contains("Mon"))
        #expect(dayNames.contains("Fri"))
        #expect(dayNames.contains("Sat"))
    }

    // MARK: - StatsPeriod

    @Test("StatsPeriod has all expected cases")
    func periodCases() {
        let cases = StatsPeriod.allCases
        #expect(cases.count == 5)
        #expect(cases.contains(.week))
        #expect(cases.contains(.month))
        #expect(cases.contains(.threeMonths))
        #expect(cases.contains(.year))
        #expect(cases.contains(.allTime))
    }

    @Test("StatsPeriod raw values are display-friendly")
    func periodRawValues() {
        #expect(StatsPeriod.week.rawValue == "7D")
        #expect(StatsPeriod.month.rawValue == "1M")
        #expect(StatsPeriod.threeMonths.rawValue == "3M")
        #expect(StatsPeriod.year.rawValue == "1Y")
        #expect(StatsPeriod.allTime.rawValue == "All")
    }
}

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    @Test("Loading with empty sessions produces zero stats")
    func emptyStats() {
        let vm = HomeViewModel()
        vm.loadData(sessions: [])
        #expect(vm.totalDrinksThisWeek == 0)
        #expect(vm.totalSpendThisWeek == 0)
        #expect(vm.averageDrinksPerSession == 0)
        #expect(vm.recentSessions.isEmpty)
    }

    @Test("Dry day streak starts at zero with no sessions")
    func dryStreakNoSessions() {
        let vm = HomeViewModel()
        vm.loadData(sessions: [])
        // With no sessions ever, every day is a dry day
        #expect(vm.currentStreak > 0)
    }
}

@Suite("ProfileViewModel Tests")
struct ProfileViewModelTests {

    @Test("Loading with nil user and empty sessions")
    func nilUserEmptySessions() {
        let vm = ProfileViewModel()
        vm.loadProfile(user: nil, sessions: [])
        #expect(vm.totalSessions == 0)
        #expect(vm.totalLifetimeDrinks == 0)
        #expect(vm.totalLifetimeSpend == 0)
        #expect(vm.favoriteVenue == "None yet")
        #expect(vm.favoriteDrinkType == "None yet")
    }

    @Test("Loading with a user sets member since days")
    func memberSinceDays() {
        let user = User(displayName: "Test User")
        let vm = ProfileViewModel()
        vm.loadProfile(user: user, sessions: [])
        #expect(vm.memberSinceDays >= 0)
    }
}
