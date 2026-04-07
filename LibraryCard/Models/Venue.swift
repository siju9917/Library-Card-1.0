import Foundation
import SwiftData

@Model
final class Venue {
    var id: UUID
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var category: VenueCategory
    var visitCount: Int
    var totalSpent: Double
    var lastVisited: Date?
    var isFavorite: Bool

    @Relationship(deleteRule: .nullify, inverse: \DrinkingSession.venue)
    var sessions: [DrinkingSession] = []

    @Relationship(deleteRule: .nullify, inverse: \Drink.venue)
    var drinks: [Drink] = []

    /// Validated initializer. Throws `ValidationError` for invalid inputs.
    init(
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        category: VenueCategory = .bar
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyName("Venue name cannot be empty.")
        }

        if let lat = latitude {
            guard lat >= -90, lat <= 90 else {
                throw ValidationError.invalidCoordinates("Latitude must be between -90 and 90.")
            }
        }
        if let lon = longitude {
            guard lon >= -180, lon <= 180 else {
                throw ValidationError.invalidCoordinates("Longitude must be between -180 and 180.")
            }
        }

        self.id = UUID()
        self.name = trimmedName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.visitCount = 0
        self.totalSpent = 0
        self.lastVisited = nil
        self.isFavorite = false
    }

    var averageSpendPerVisit: Double {
        guard visitCount > 0 else { return 0 }
        return totalSpent / Double(visitCount)
    }

    func recordVisit(amount: Double) {
        visitCount += 1
        totalSpent += max(amount, 0)
        lastVisited = Date()
    }
}

enum VenueCategory: String, Codable, CaseIterable, Identifiable {
    case bar = "Bar"
    case restaurant = "Restaurant"
    case club = "Club"
    case brewery = "Brewery"
    case winery = "Winery"
    case liquorStore = "Liquor Store"
    case home = "Home"
    case event = "Event"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bar: return "wineglass"
        case .restaurant: return "fork.knife"
        case .club: return "music.note"
        case .brewery: return "mug"
        case .winery: return "leaf"
        case .liquorStore: return "bag"
        case .home: return "house"
        case .event: return "star"
        case .other: return "mappin"
        }
    }
}
