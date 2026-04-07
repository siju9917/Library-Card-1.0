import UIKit

/// Centralized haptic feedback service.
final class HapticService {
    static let shared = HapticService()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm generators for responsiveness
        impactLight.prepare()
        impactMedium.prepare()
        selection.prepare()
    }

    func drinkAdded() {
        impactMedium.impactOccurred()
    }

    func sessionStart() {
        notification.notificationOccurred(.success)
    }

    func sessionEnd() {
        impactHeavy.impactOccurred()
    }

    func quickAction() {
        impactLight.impactOccurred()
    }

    func selectionChanged() {
        selection.selectionChanged()
    }

    func error() {
        notification.notificationOccurred(.error)
    }

    func warning() {
        notification.notificationOccurred(.warning)
    }
}
