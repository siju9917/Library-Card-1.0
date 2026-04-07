import Foundation
import SwiftData

@Model
final class Drink {
    var id: UUID
    var type: DrinkType
    var name: String
    var sizeMl: Double
    var alcoholPercentage: Double
    var price: Double?
    var timestamp: Date
    var isAutoLogged: Bool
    var calories: Double

    var session: DrinkingSession?
    var venue: Venue?

    init(
        type: DrinkType,
        name: String,
        sizeMl: Double,
        alcoholPercentage: Double,
        price: Double? = nil,
        isAutoLogged: Bool = false,
        session: DrinkingSession? = nil,
        venue: Venue? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.sizeMl = sizeMl
        self.alcoholPercentage = alcoholPercentage
        self.price = price
        self.timestamp = Date()
        self.isAutoLogged = isAutoLogged
        self.calories = Drink.calculateCalories(sizeMl: sizeMl, alcoholPercentage: alcoholPercentage)
        self.session = session
        self.venue = venue
    }

    /// Standard drink units (1 US standard = 14g pure alcohol)
    var standardUnits: Double {
        let mlAlcohol = sizeMl * (alcoholPercentage / 100)
        let gramsAlcohol = mlAlcohol * 0.789 // density of ethanol
        return gramsAlcohol / 14.0
    }

    var sizeFormatted: String {
        if sizeMl >= 1000 {
            return String(format: "%.1fL", sizeMl / 1000)
        }
        return "\(Int(sizeMl))ml"
    }

    static func calculateCalories(sizeMl: Double, alcoholPercentage: Double) -> Double {
        let mlAlcohol = sizeMl * (alcoholPercentage / 100)
        let gramsAlcohol = mlAlcohol * 0.789
        return gramsAlcohol * 7.0 // 7 calories per gram of alcohol
    }
}

enum DrinkType: String, Codable, CaseIterable, Identifiable {
    case beer = "Beer"
    case wine = "Wine"
    case cocktail = "Cocktail"
    case spirit = "Spirit"
    case shot = "Shot"
    case hardSeltzer = "Hard Seltzer"
    case cider = "Cider"
    case sake = "Sake"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .beer: return "mug.fill"
        case .wine: return "wineglass.fill"
        case .cocktail: return "waterbottle.fill"
        case .spirit: return "cup.and.saucer.fill"
        case .shot: return "drop.fill"
        case .hardSeltzer: return "bubbles.and.sparkles.fill"
        case .cider: return "leaf.fill"
        case .sake: return "cup.and.saucer.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var defaultSizeMl: Double {
        switch self {
        case .beer: return 355       // 12oz
        case .wine: return 148       // 5oz
        case .cocktail: return 240   // 8oz
        case .spirit: return 44      // 1.5oz
        case .shot: return 44        // 1.5oz
        case .hardSeltzer: return 355 // 12oz
        case .cider: return 355      // 12oz
        case .sake: return 180       // 6oz
        case .other: return 355
        }
    }

    var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0
        case .wine: return 12.5
        case .cocktail: return 15.0
        case .spirit: return 40.0
        case .shot: return 40.0
        case .hardSeltzer: return 5.0
        case .cider: return 5.0
        case .sake: return 15.0
        case .other: return 5.0
        }
    }
}
