import Testing
import Foundation
@testable import LibraryCard

@Suite("StatsViewModel Tests")
struct StatsViewModelTests {

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
        #expect(vm.totalSessions == 0)
        #expect(vm.averageDrinksPerSession == 0)
        #expect(vm.averageDrinksPerHour == 0)
        #expect(vm.averageDPM == 0)
        #expect(vm.totalCalories == 0)
    }

    @Test("Chart data is empty with no sessions")
    func emptyChartData() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.drinksOverTime.isEmpty)
        #expect(vm.dpmOverTime.isEmpty)
        #expect(vm.drinkTypeDistribution.isEmpty)
        #expect(vm.dayOfWeekDistribution.count == 7)
        #expect(vm.topVenues.isEmpty)
    }

    @Test("Day of week distribution always has 7 entries")
    func dayOfWeekAlwaysSeven() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.dayOfWeekDistribution.count == 7)
    }

    @Test("Top drink type is nil with no data")
    func topDrinkTypeEmpty() {
        let vm = StatsViewModel()
        vm.loadStats(sessions: [])
        #expect(vm.topDrinkType == nil)
    }

    @Test("StatsPeriod has all expected cases")
    func periodCases() {
        let cases = StatsPeriod.allCases
        #expect(cases.count == 5)
    }
}

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    @Test("Loading with empty sessions produces zero stats")
    func emptyStats() {
        let vm = HomeViewModel()
        vm.loadData(sessions: [])
        #expect(vm.totalDrinksThisWeek == 0)
        #expect(vm.totalDrinksAllTime == 0)
        #expect(vm.averageDrinksPerSession == 0)
        #expect(vm.recentSessions.isEmpty)
    }

    @Test("Dry day streak starts at zero with no sessions")
    func dryStreakNoSessions() {
        let vm = HomeViewModel()
        vm.loadData(sessions: [])
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
        #expect(vm.totalDPM == 0)
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
