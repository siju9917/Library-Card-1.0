import SwiftUI

/// Global alert manager for showing user-facing errors and confirmations.
@MainActor
final class AlertManager: ObservableObject {
    static let shared = AlertManager()

    @Published var isShowing = false
    @Published var title = ""
    @Published var message = ""
    @Published var style: AlertStyle = .error

    enum AlertStyle {
        case error
        case success
        case info
    }

    private init() {}

    func show(_ error: AppError) {
        title = "Error"
        message = error.userMessage
        style = .error
        isShowing = true
    }

    func showError(_ message: String) {
        self.title = "Error"
        self.message = message
        self.style = .error
        self.isShowing = true
    }

    func showSuccess(_ message: String) {
        self.title = "Success"
        self.message = message
        self.style = .success
        self.isShowing = true
    }

    func showInfo(title: String, message: String) {
        self.title = title
        self.message = message
        self.style = .info
        self.isShowing = true
    }
}

/// View modifier that attaches the global alert system to any view.
struct GlobalAlertModifier: ViewModifier {
    @ObservedObject var alertManager = AlertManager.shared

    func body(content: Content) -> some View {
        content
            .alert(alertManager.title, isPresented: $alertManager.isShowing) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertManager.message)
            }
    }
}

extension View {
    func withGlobalAlerts() -> some View {
        modifier(GlobalAlertModifier())
    }
}
