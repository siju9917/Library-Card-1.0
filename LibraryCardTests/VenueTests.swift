import Testing
import Foundation
@testable import LibraryCard

@Suite("Venue Model Tests")
struct VenueTests {

    @Test("Creates venue with valid parameters")
    func validVenueCreation() throws {
        let venue = try Venue(
            name: "The Pub",
            address: "123 Main St",
            latitude: 40.7128,
            longitude: -74.0060,
            category: .bar
        )

        #expect(venue.name == "The Pub")
        #expect(venue.address == "123 Main St")
        #expect(venue.latitude == 40.7128)
        #expect(venue.category == .bar)
        #expect(venue.visitCount == 0)
        #expect(!venue.isFavorite)
    }

    @Test("Trims whitespace from venue name")
    func trimsName() throws {
        let venue = try Venue(name: "  The Bar  ")
        #expect(venue.name == "The Bar")
    }

    @Test("Rejects empty name")
    func rejectsEmptyName() {
        #expect(throws: ValidationError.self) {
            try Venue(name: "")
        }
    }

    @Test("Rejects whitespace-only name")
    func rejectsWhitespaceName() {
        #expect(throws: ValidationError.self) {
            try Venue(name: "   ")
        }
    }

    @Test("Rejects invalid latitude above 90")
    func rejectsHighLatitude() {
        #expect(throws: ValidationError.self) {
            try Venue(name: "Bar", latitude: 91)
        }
    }

    @Test("Rejects invalid latitude below -90")
    func rejectsLowLatitude() {
        #expect(throws: ValidationError.self) {
            try Venue(name: "Bar", latitude: -91)
        }
    }

    @Test("Rejects invalid longitude above 180")
    func rejectsHighLongitude() {
        #expect(throws: ValidationError.self) {
            try Venue(name: "Bar", longitude: 181)
        }
    }

    @Test("Accepts nil coordinates")
    func acceptsNilCoordinates() throws {
        let venue = try Venue(name: "Home Bar")
        #expect(venue.latitude == nil)
        #expect(venue.longitude == nil)
    }

    @Test("Records visits correctly")
    func recordVisit() throws {
        let venue = try Venue(name: "Bar")
        venue.recordVisit()
        #expect(venue.visitCount == 1)
        #expect(venue.lastVisited != nil)
    }

    @Test("Records multiple visits")
    func recordMultipleVisits() throws {
        let venue = try Venue(name: "Bar")
        venue.recordVisit()
        venue.recordVisit()
        venue.recordVisit()
        #expect(venue.visitCount == 3)
    }

    @Test("All venue categories have icons")
    func allCategoriesHaveIcons() {
        for category in VenueCategory.allCases {
            #expect(!category.icon.isEmpty)
            #expect(!category.rawValue.isEmpty)
        }
    }
}
