import Foundation

/// Protocol for notification operations.
/// Enables dependency injection and testability.
protocol NotificationManaging {
    func requestPermission() async -> Bool
    func sendDrinkAutoLoggedNotification(merchantName: String, amount: Double)
    func sendPaceCheckNotification(drinksPerHour: Double, totalDrinks: Int)
    func scheduleInactivityReminder(afterMinutes: Int)
    func cancelInactivityReminder()
    func registerCategories()
}
