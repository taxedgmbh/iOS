//
//  ErrorHandler.swift
//  TaxedGmbH_IOS
//
//  Centralized error handling utility
//

import Foundation
import SwiftUI
import Combine

// MARK: - App Errors

enum AppError: LocalizedError {
    case authentication(String)
    case network(String)
    case validation(String)
    case firebase(String)
    case storage(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .authentication(let message):
            return "\("error.authentication.prefix".localized): \(message)"
        case .network(let message):
            return "\("error.network.prefix".localized): \(message)"
        case .validation(let message):
            return "\("error.validation.prefix".localized): \(message)"
        case .firebase(let message):
            return "\("error.firebase.prefix".localized): \(message)"
        case .storage(let message):
            return "\("error.storage.prefix".localized): \(message)"
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authentication:
            return "error.authentication.recovery".localized
        case .network:
            return "error.network.recovery".localized
        case .validation:
            return "error.validation.recovery".localized
        case .firebase:
            return "error.firebase.recovery".localized
        case .storage:
            return "error.storage.recovery".localized
        case .unknown:
            return "error.unknown.recovery".localized
        }
    }
}

// MARK: - Error Handler

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError: Bool = false

    func handle(_ error: Error, context: String = "") {
        print("❌ Error [\(context)]: \(error.localizedDescription)")

        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .unknown(error.localizedDescription)
        }

        showError = true
    }

    func clear() {
        currentError = nil
        showError = false
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorHandler.showError) {
                Alert(
                    title: Text("common.error".localized),
                    message: Text(errorHandler.currentError?.localizedDescription ?? .genericError),
                    primaryButton: .default(Text("common.ok".localized)) {
                        errorHandler.clear()
                    },
                    secondaryButton: .cancel(Text("common.cancel".localized)) {
                        errorHandler.clear()
                    }
                )
            }
    }
}

extension View {
    func errorAlert(_ errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
}
