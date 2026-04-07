import Foundation
import SwiftData

/// BeReal-style photo earned by logging drinks. Each drink gives one photo post.
/// Photos reset at the end of the session.
@Model
final class SessionPhoto {
    var id: UUID
    var imageData: Data?
    var caption: String?
    var timestamp: Date
    var drinkNumber: Int  // which drink number earned this photo

    var session: DrinkingSession?
    var user: User?
    var venue: Venue?

    init(
        imageData: Data? = nil,
        caption: String? = nil,
        drinkNumber: Int,
        session: DrinkingSession? = nil,
        user: User? = nil,
        venue: Venue? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.caption = caption
        self.timestamp = Date()
        self.drinkNumber = drinkNumber
        self.session = session
        self.user = user
        self.venue = venue
    }
}
