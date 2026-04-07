import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Notify user when a drink purchase is auto-detected from a card transaction
    func sendDrinkAutoLoggedNotification(merchantName: String, amount: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Drink Logged"
        content.body = "Detected \(amount.currencyFormatted) at \(merchantName)"
        content.sound = .default
        content.categoryIdentifier = "DRINK_LOGGED"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Notify user of their session pace
    func sendPaceCheckNotification(drinksPerHour: Double, totalDrinks: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Pace Check"
        content.body = "You're at \(totalDrinks) drinks (\(String(format: "%.1f", drinksPerHour))/hr)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pace_check",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Remind user to log drinks if session is active but no drinks logged recently
    func scheduleInactivityReminder(afterMinutes: Int = 60) {
        let content = UNMutableNotificationContent()
        content.title = "Still Out?"
        content.body = "Don't forget to log your drinks, or end your session."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(afterMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "inactivity_reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelInactivityReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])
    }

    /// Register notification categories for actionable notifications
    func registerCategories() {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM_DRINK",
            title: "Confirm",
            options: []
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_DRINK",
            title: "Not a Drink",
            options: .destructive
        )

        let drinkLoggedCategory = UNNotificationCategory(
            identifier: "DRINK_LOGGED",
            actions: [confirmAction, dismissAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([drinkLoggedCategory])
    }
}
