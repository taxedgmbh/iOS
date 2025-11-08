//
//  AppConstants.swift
//  TaxedGmbH_IOS
//
//  App-wide constants following Apple best practices
//

import Foundation
import SwiftUI

// MARK: - App Constants

struct AppConstants {

    // MARK: - App Information

    struct App {
        static let name = "Taxed GmbH"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.taxed.app"
    }

    // MARK: - Firebase

    struct Firebase {
        static let projectId = "taxedgmbh"

        // Database Configuration
        // Database ID: taxedgmbh (custom database, not default)
        // Location: europe-west6
        static let databaseId: String? = "taxedgmbh"

        struct Collections {
            static let users = "users"
            static let documents = "documents"
            static let chats = "chats"
            static let messages = "messages"
            static let notifications = "notifications"

            // Workspace Management (for collaborative tax filing)
            static let workspaces = "workspaces"
            static let workspaceInvitations = "workspaceInvitations"

            // Legacy/alternative names (kept for backward compatibility)
            static let conversations = "chats" // Alias for chats
            static let taxCases = "taxCases" // Future use
        }

        struct Storage {
            static let documentsPath = "documents"
            static let profileImagesPath = "profileImages"
        }
    }

    // MARK: - Tax Configuration

    struct Tax {
        static let currentYear = 2024
        static let requiredDocumentCount = 15

        struct Categories {
            static let income = "income"
            static let deduction = "deduction"
            static let pillar = "pillar"
            static let wealth = "wealth"
        }
    }

    // MARK: - UI Constants

    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24

        struct Animation {
            static let defaultDuration: Double = 0.3
            static let springResponse: Double = 0.5
            static let springDamping: Double = 0.7
        }
    }

    // MARK: - Validation

    struct Validation {
        static let minimumPasswordLength = 8
        static let maximumFileSize: Int64 = 10 * 1024 * 1024 // 10MB
        static let supportedImageTypes = ["image/jpeg", "image/png", "image/heic"]
    }

    // MARK: - Localization

    struct Localization {
        static let defaultLanguage = "de" // German for Swiss users
        static let supportedLanguages = ["de", "fr", "it", "en"]
    }

    // MARK: - Company Branding

    struct Branding {
        static let companyName = "Taxed GmbH"
        static let companyNameShort = "Taxed"
        static let tagline = "Professionelle Steuerberatung für die Schweiz"
        static let taglineEN = "Professional Tax Consulting for Switzerland"
        static let taglineFR = "Conseil fiscal professionnel pour la Suisse"
        static let taglineIT = "Consulenza fiscale professionale per la Svizzera"

        struct Contact {
            static let email = "info@taxed.ch"
            static let phone = "+41 79 910 77 87"
            static let website = "https://taxed.ch"
        }

        struct Address {
            static let street = "Aegertenstrasse 10"
            static let city = "Biel/Bienne"
            static let postalCode = "2503"
            static let country = "Switzerland"
            static let fullAddress = "\(street), \(postalCode) \(city), \(country)"
        }

        struct Social {
            static let linkedIn = "https://linkedin.com/company/taxed-gmbh"
            static let instagram = "https://instagram.com/taxed.ch"
        }
    }
}

// MARK: - Color Extensions (Apple Best Practice)

extension Color {
    // Category Colors
    static let categoryIncome = Color.green
    static let categoryDeduction = Color.blue
    static let categoryPillar = Color.purple
    static let categoryWealth = Color.orange

    // Status Colors
    static let statusPending = Color.orange
    static let statusProcessing = Color.blue
    static let statusApproved = Color.green
    static let statusRejected = Color.red
}

// MARK: - String Constants

extension String {
    // Error Messages
    static let genericError = "Ein Fehler ist aufgetreten"
    static let networkError = "Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung"
    static let authenticationError = "Authentifizierungsfehler"

    // Success Messages
    static let uploadSuccess = "Erfolgreich hochgeladen"
    static let documentProcessed = "Dokument verarbeitet"

    // Placeholders
    static let emailPlaceholder = "E-Mail"
    static let passwordPlaceholder = "Passwort"
    static let namePlaceholder = "Name"
}
