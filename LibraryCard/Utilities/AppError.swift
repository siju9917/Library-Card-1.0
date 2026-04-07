import Foundation
import os

/// Centralized error types for the app.
enum AppError: LocalizedError {
    case validation(String)
    case persistence(String)
    case authentication(String)
    case network(String)
    case cardService(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message): return message
        case .persistence(let message): return message
        case .authentication(let message): return message
        case .network(let message): return message
        case .cardService(let message): return message
        case .unknown(let message): return message
        }
    }

    var userMessage: String {
        switch self {
        case .validation(let message): return message
        case .persistence: return "Something went wrong saving your data. Please try again."
        case .authentication: return "Authentication failed. Please try again."
        case .network: return "Network error. Please check your connection."
        case .cardService: return "Card service unavailable. Please try again later."
        case .unknown: return "An unexpected error occurred."
        }
    }

    // MARK: - Logging

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.librarycard",
        category: "AppError"
    )

    static func log(_ error: AppError, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("[\(fileName):\(line)] \(error.errorDescription ?? "Unknown error")")
    }
}

/// Validation errors thrown by model constructors.
enum ValidationError: LocalizedError {
    case invalidSize(String)
    case invalidPercentage(String)
    case invalidPrice(String)
    case invalidWeight(String)
    case invalidBudget(String)
    case emptyName(String)
    case invalidCoordinates(String)

    var errorDescription: String? {
        switch self {
        case .invalidSize(let msg): return msg
        case .invalidPercentage(let msg): return msg
        case .invalidPrice(let msg): return msg
        case .invalidWeight(let msg): return msg
        case .invalidBudget(let msg): return msg
        case .emptyName(let msg): return msg
        case .invalidCoordinates(let msg): return msg
        }
    }
}
