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
    var lastVisited: Date?
    var isFavorite: Bool

    @Relationship(deleteRule: .nullify, inverse: \DrinkingSession.venue)
    var sessions: [DrinkingSession] = []

    @Relationship(deleteRule: .nullify, inverse: \Drink.venue)
    var drinks: [Drink] = []

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
        self.lastVisited = nil
        self.isFavorite = false
    }

    /// Total drinks ever consumed at this venue
    var totalDrinksHere: Int {
        drinks.count
    }

    /// Number of active Library Card users at this venue right now
    var currentActiveUsers: Int {
        sessions.filter { $0.isActive }.count
    }

    /// Number of drinks being consumed right now (active sessions)
    var currentLiveDrinks: Int {
        sessions.filter { $0.isActive }.reduce(0) { $0 + $1.totalDrinks }
    }

    func recordVisit() {
        visitCount += 1
        lastVisited = Date()
    }
}

enum VenueCategory: String, Codable, CaseIterable, Identifiable {
    case bar = "Bar"
    case restaurant = "Restaurant"
    case club = "Club"
    case brewery = "Brewery"
    case winery = "Winery"
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
        case .home: return "house"
        case .event: return "star"
        case .other: return "mappin"
        }
    }
}
