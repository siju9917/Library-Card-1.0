import Testing
import Foundation
@testable import LibraryCard

@Suite("DateFormatters Tests")
struct DateFormatterTests {

    @Test("Currency formatting for typical amounts")
    func currencyFormatting() {
        #expect(8.50.currencyFormatted.contains("8"))
        #expect(0.0.currencyFormatted.contains("0"))
    }

    @Test("Duration formatting for minutes only")
    func durationMinutes() {
        let interval: TimeInterval = 45 * 60
        #expect(interval.durationFormatted == "45m")
    }

    @Test("Duration formatting for hours and minutes")
    func durationHoursMinutes() {
        let interval: TimeInterval = 2 * 3600 + 30 * 60
        #expect(interval.durationFormatted == "2h 30m")
    }

    @Test("Timer formatting for HH:MM:SS")
    func timerFormatting() {
        let interval: TimeInterval = 1 * 3600 + 23 * 60 + 45
        #expect(interval.timerFormatted == "01:23:45")
    }

    @Test("Timer formatting for zero")
    func timerZero() {
        let interval: TimeInterval = 0
        #expect(interval.timerFormatted == "00:00:00")
    }

    @Test("Duration formatting for zero")
    func durationZero() {
        let interval: TimeInterval = 0
        #expect(interval.durationFormatted == "0m")
    }
}

@Suite("Wrapped Generator Tests")
struct WrappedGeneratorTests {

    @Test("Generates empty wrapped with no sessions")
    func emptyWrapped() {
        let range = WrappedGenerator.periodRange(for: .weekly)
        let wrapped = WrappedGenerator.generate(
            userId: UUID(),
            sessions: [],
            period: .weekly,
            periodStart: range.start,
            periodEnd: range.end
        )
        #expect(wrapped.totalDrinks == 0)
        #expect(wrapped.totalSessions == 0)
        #expect(wrapped.averageDPM == 0)
    }

    @Test("Period range for weekly is 7 days")
    func weeklyRange() {
        let range = WrappedGenerator.periodRange(for: .weekly)
        let days = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 0
        #expect(days == 7)
    }

    @Test("Period range for monthly is roughly 30 days")
    func monthlyRange() {
        let range = WrappedGenerator.periodRange(for: .monthly)
        let days = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 0
        #expect(days >= 28 && days <= 31)
    }

    @Test("Period range for yearly is roughly 365 days")
    func yearlyRange() {
        let range = WrappedGenerator.periodRange(for: .yearly)
        let days = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 0
        #expect(days >= 365 && days <= 366)
    }

    @Test("WrappedPeriod has all cases")
    func allPeriodCases() {
        #expect(WrappedPeriod.allCases.count == 3)
    }
}

@Suite("Showdown Model Tests")
struct ShowdownTests {

    @Test("Creates showdown in setup status")
    func showdownCreation() {
        let showdown = Showdown(name: "Friday Night")
        #expect(showdown.name == "Friday Night")
        #expect(showdown.status == .setup)
        #expect(!showdown.isActive)
    }

    @Test("Starts showdown correctly")
    func showdownStart() {
        let showdown = Showdown(name: "Test")
        showdown.start()
        #expect(showdown.isActive)
        #expect(showdown.status == .active)
        #expect(showdown.startTime != nil)
    }

    @Test("Ends showdown correctly")
    func showdownEnd() {
        let showdown = Showdown(name: "Test")
        showdown.start()
        showdown.end()
        #expect(!showdown.isActive)
        #expect(showdown.status == .completed)
        #expect(showdown.endTime != nil)
    }

    @Test("ShowdownStatus has all cases")
    func statusCases() {
        #expect(ShowdownStatus.allCases.count == 4)
    }
}

@Suite("Organization Model Tests")
struct OrganizationTests {

    @Test("Creates organization correctly")
    func orgCreation() {
        let org = Organization(name: "Sigma Chi", handle: "sigma_chi")
        #expect(org.name == "Sigma Chi")
        #expect(org.handle == "sigma_chi")
        #expect(!org.isPremium)
        #expect(org.memberCount == 0)
        #expect(org.totalOrgDrinks == 0)
    }

    @Test("Handle is lowercased")
    func handleLowercased() {
        let org = Organization(name: "Test", handle: "MyOrg")
        #expect(org.handle == "myorg")
    }
}
