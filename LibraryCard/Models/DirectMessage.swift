import Foundation
import SwiftData

/// Direct messages between users.
@Model
final class DirectMessage {
    var id: UUID
    var senderUserId: UUID
    var senderDisplayName: String
    var recipientUserId: UUID
    var recipientDisplayName: String
    var content: String
    var timestamp: Date
    var isRead: Bool

    init(
        senderUserId: UUID,
        senderDisplayName: String,
        recipientUserId: UUID,
        recipientDisplayName: String,
        content: String
    ) {
        self.id = UUID()
        self.senderUserId = senderUserId
        self.senderDisplayName = senderDisplayName
        self.recipientUserId = recipientUserId
        self.recipientDisplayName = recipientDisplayName
        self.content = content
        self.timestamp = Date()
        self.isRead = false
    }
}

/// A conversation thread between two users (for grouping DMs).
@Model
final class Conversation {
    var id: UUID
    var participantOneId: UUID
    var participantOneName: String
    var participantTwoId: UUID
    var participantTwoName: String
    var lastMessagePreview: String?
    var lastMessageTimestamp: Date?
    var unreadCount: Int

    @Relationship(deleteRule: .cascade)
    var messages: [DirectMessage] = []

    init(
        participantOneId: UUID,
        participantOneName: String,
        participantTwoId: UUID,
        participantTwoName: String
    ) {
        self.id = UUID()
        self.participantOneId = participantOneId
        self.participantOneName = participantOneName
        self.participantTwoId = participantTwoId
        self.participantTwoName = participantTwoName
        self.lastMessagePreview = nil
        self.lastMessageTimestamp = nil
        self.unreadCount = 0
    }

    func otherParticipantName(currentUserId: UUID) -> String {
        currentUserId == participantOneId ? participantTwoName : participantOneName
    }

    func otherParticipantId(currentUserId: UUID) -> UUID {
        currentUserId == participantOneId ? participantTwoId : participantOneId
    }
}
