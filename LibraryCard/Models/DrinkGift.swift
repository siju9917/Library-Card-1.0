import Foundation
import SwiftData

/// A drink gift sent from one user to another.
/// "Buy your friend a drink" — loads their Library Card with one drink.
@Model
final class DrinkGift {
    var id: UUID
    var senderUserId: UUID
    var senderDisplayName: String
    var recipientUserId: UUID
    var recipientDisplayName: String
    var drinkType: DrinkType?
    var message: String?
    var occasion: GiftOccasion
    var timestamp: Date
    var status: GiftStatus
    var requiresLivePhoto: Bool

    /// Live Photo verification data (for bar gifting to strangers)
    var livePhotoVerified: Bool

    init(
        senderUserId: UUID,
        senderDisplayName: String,
        recipientUserId: UUID,
        recipientDisplayName: String,
        drinkType: DrinkType? = nil,
        message: String? = nil,
        occasion: GiftOccasion = .justBecause,
        requiresLivePhoto: Bool = false
    ) {
        self.id = UUID()
        self.senderUserId = senderUserId
        self.senderDisplayName = senderDisplayName
        self.recipientUserId = recipientUserId
        self.recipientDisplayName = recipientDisplayName
        self.drinkType = drinkType
        self.message = message
        self.occasion = occasion
        self.timestamp = Date()
        self.status = .pending
        self.requiresLivePhoto = requiresLivePhoto
        self.livePhotoVerified = false
    }

    func accept() {
        status = .accepted
    }

    func decline() {
        status = .declined
    }
}

enum GiftOccasion: String, Codable, CaseIterable {
    case birthday = "Birthday"
    case celebration = "Celebration"
    case justBecause = "Just Because"
    case apology = "Apology"
    case congrats = "Congrats"
    case welcome = "Welcome"

    var icon: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .celebration: return "party.popper.fill"
        case .justBecause: return "heart.fill"
        case .apology: return "hand.wave.fill"
        case .congrats: return "star.fill"
        case .welcome: return "figure.wave"
        }
    }
}

enum GiftStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
}
