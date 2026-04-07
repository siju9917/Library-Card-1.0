import Foundation
import UserNotifications

/// Handles funny/social notifications like morning-after messages,
/// friend departure alerts, SOS alerts, and match notifications.
final class FunNotificationService {
    static let shared = FunNotificationService()

    private init() {}

    // MARK: - Morning After Notifications

    /// Schedule a funny morning-after notification based on how many drinks were logged.
    func scheduleMorningAfter(totalDrinks: Int, sessionEndTime: Date) {
        let calendar = Calendar.current
        guard let nextMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of:
            calendar.date(byAdding: .day, value: 1, to: sessionEndTime) ?? sessionEndTime
        ) else { return }

        let message = morningMessage(for: totalDrinks)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = "MORNING_AFTER"

        let timeInterval = nextMorning.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "morning_after_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func morningMessage(for drinks: Int) -> (title: String, body: String) {
        let messages: [(String, String)]

        switch drinks {
        case 0:
            messages = [
                ("Designated driver mode", "Respect. Your liver says thanks."),
                ("Sober legend", "Not a single drink? That's honestly impressive.")
            ]
        case 1...3:
            messages = [
                ("Easy night?", "Only \(drinks) drinks. Very responsible of you."),
                ("Light work", "\(drinks) drinks? That's a Tuesday."),
                ("Casual vibes", "A chill \(drinks)-drink night. Your future self appreciates it.")
            ]
        case 4...6:
            messages = [
                ("Rough morning I presume?", "\(drinks) drinks last night. Hydrate."),
                ("How's the head?", "\(drinks) drinks deep. Water is your friend today."),
                ("Good morning sunshine", "Remember those \(drinks) drinks? Your body does.")
            ]
        case 7...10:
            messages = [
                ("Survivor", "\(drinks) drinks and you're still here. Legendary."),
                ("Yikes", "\(drinks) drinks?! Please drink water. Lots of it."),
                ("Big night energy", "\(drinks) drinks. We're not judging. Ok maybe a little.")
            ]
        default:
            messages = [
                ("Are you alive?", "\(drinks) drinks last night. Blink twice if you need help."),
                ("Absolute unit", "\(drinks) drinks. That's not a session, that's a statement."),
                ("Check in with us", "\(drinks) drinks... You good? Seriously though, hydrate.")
            ]
        }

        return messages.randomElement() ?? ("Good morning", "Hope you had fun last night!")
    }

    // MARK: - Friend Departure Notification

    func sendFriendDepartedNotification(friendName: String, venueName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(friendName) left"
        content.body = "\(friendName) just left \(venueName)"
        content.sound = .default
        content.categoryIdentifier = "FRIEND_DEPARTED"

        let request = UNNotificationRequest(
            identifier: "departure_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - SOS Notification

    func sendSOSNotification(fromUser: String, venueName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "SOS from \(fromUser)"
        content.body = venueName != nil
            ? "\(fromUser) needs help at \(venueName!). Check on them."
            : "\(fromUser) needs help. Check on them."
        content.sound = .defaultCritical
        content.categoryIdentifier = "SOS_ALERT"
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "sos_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Match Notification

    func sendMatchNotification(matchedUserName: String, venueName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "It's a match!"
        content.body = venueName != nil
            ? "You and \(matchedUserName) matched at \(venueName!)."
            : "You and \(matchedUserName) matched. Say hi!"
        content.sound = .default
        content.categoryIdentifier = "MATCH"

        let request = UNNotificationRequest(
            identifier: "match_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Drink Gift Notification

    func sendDrinkGiftNotification(fromUser: String, occasion: GiftOccasion) {
        let content = UNMutableNotificationContent()
        content.title = "Someone bought you a drink!"
        content.body = "\(fromUser) sent you a drink for \(occasion.rawValue.lowercased()). Open the app to accept."
        content.sound = .default
        content.categoryIdentifier = "DRINK_GIFT"

        let request = UNNotificationRequest(
            identifier: "gift_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Pre-Swipe Match Arrived

    func sendPreSwipeArrivedNotification(matchedUserName: String, venueName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Your pre-match is here!"
        content.body = "\(matchedUserName) just checked in at \(venueName). You both pre-swiped right!"
        content.sound = .default
        content.categoryIdentifier = "PRE_SWIPE_ARRIVED"

        let request = UNNotificationRequest(
            identifier: "preswipe_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Register Categories

    func registerCategories() {
        let categories: [UNNotificationCategory] = [
            UNNotificationCategory(identifier: "MORNING_AFTER", actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "FRIEND_DEPARTED", actions: [], intentIdentifiers: []),
            UNNotificationCategory(
                identifier: "SOS_ALERT",
                actions: [
                    UNNotificationAction(identifier: "ACKNOWLEDGE_SOS", title: "I'm on it", options: []),
                    UNNotificationAction(identifier: "CALL_911", title: "Call 911", options: .foreground)
                ],
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: "MATCH",
                actions: [
                    UNNotificationAction(identifier: "SEND_MESSAGE", title: "Say Hi", options: .foreground)
                ],
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: "DRINK_GIFT",
                actions: [
                    UNNotificationAction(identifier: "ACCEPT_GIFT", title: "Accept", options: []),
                    UNNotificationAction(identifier: "DECLINE_GIFT", title: "Decline", options: .destructive)
                ],
                intentIdentifiers: []
            ),
            UNNotificationCategory(identifier: "PRE_SWIPE_ARRIVED", actions: [], intentIdentifiers: [])
        ]

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}
