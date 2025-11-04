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
            return "Authentifizierung: \(message)"
        case .network(let message):
            return "Netzwerk: \(message)"
        case .validation(let message):
            return "Validierung: \(message)"
        case .firebase(let message):
            return "Firebase: \(message)"
        case .storage(let message):
            return "Speicher: \(message)"
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authentication:
            return "Bitte überprüfen Sie Ihre Anmeldedaten und versuchen Sie es erneut."
        case .network:
            return "Bitte überprüfen Sie Ihre Internetverbindung."
        case .validation:
            return "Bitte überprüfen Sie Ihre Eingaben."
        case .firebase:
            return "Ein Serverfehler ist aufgetreten. Bitte versuchen Sie es später erneut."
        case .storage:
            return "Fehler beim Hochladen. Bitte versuchen Sie es erneut."
        case .unknown:
            return "Ein unbekannter Fehler ist aufgetreten."
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
                    title: Text("Fehler"),
                    message: Text(errorHandler.currentError?.localizedDescription ?? .genericError),
                    primaryButton: .default(Text("OK")) {
                        errorHandler.clear()
                    },
                    secondaryButton: .cancel(Text("Abbrechen")) {
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
