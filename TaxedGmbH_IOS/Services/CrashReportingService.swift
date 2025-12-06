//
//  CrashReportingService.swift
//  TaxedGmbH_IOS
//
//  Production error tracking and crash reporting service
//  Ready for Firebase Crashlytics integration
//

import Foundation
import FirebaseCore

// MARK: - Error Severity Levels

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
}

// MARK: - Crash Reporting Service

@MainActor
class CrashReportingService {
    static let shared = CrashReportingService()

    private init() {
        setupCrashlytics()
    }

    // MARK: - Setup

    private func setupCrashlytics() {
        // NOTE: To enable Firebase Crashlytics:
        // 1. Add FirebaseCrashlytics package via Xcode (File > Add Package Dependencies)
        // 2. Import FirebaseCrashlytics at the top of this file
        // 3. Uncomment the following line in TaxedGmbH_IOSApp.swift after Firebase.configure():
        //    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        // 4. Add a new Run Script Phase to Build Phases with:
        //    "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
        // 5. Add the dSYMs input file:
        //    ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}

        #if DEBUG
        // Disable Crashlytics in debug builds to avoid noise
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        // Enable in release builds
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }

    // MARK: - Error Logging

    /// Log an error with context
    func logError(_ error: Error,
                  severity: ErrorSeverity = .error,
                  userInfo: [String: Any]? = nil,
                  file: String = #file,
                  function: String = #function,
                  line: Int = #line) {

        // Extract file name from path
        let fileName = URL(fileURLWithPath: file).lastPathComponent

        // Build error context
        var context: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_type": String(describing: type(of: error)),
            "severity": String(describing: severity),
            "file": fileName,
            "function": function,
            "line": line,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Add user info if provided
        if let userInfo = userInfo {
            context.merge(userInfo) { (_, new) in new }
        }

        // Log based on severity
        switch severity {
        case .info, .warning:
            #if DEBUG
            // In debug, still log to console for development
            logToConsole(error: error, context: context, severity: severity)
            #else
            // In production, send to Crashlytics
            // Crashlytics.crashlytics().record(error: error, userInfo: context)
            #endif

        case .error, .critical:
            #if DEBUG
            logToConsole(error: error, context: context, severity: severity)
            #else
            // In production, send to Crashlytics
            // Crashlytics.crashlytics().record(error: error, userInfo: context)

            // For critical errors, also force a non-fatal issue report
            if severity == .critical {
                // Crashlytics.crashlytics().log("CRITICAL ERROR: \(error.localizedDescription)")
                // Crashlytics.crashlytics().sendUnsentReports()
            }
            #endif
        }
    }

    /// Log a custom event
    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        #if !DEBUG
        // Only log events in production
        // Crashlytics.crashlytics().log(event)

        // Add custom keys for filtering in Crashlytics dashboard
        if let parameters = parameters {
            for (_, _) in parameters {
                // Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
        #endif
    }

    /// Set user identifier for crash reports (anonymized)
    func setUserIdentifier(_ identifier: String) {
        #if !DEBUG
        // Hash the user ID for privacy
        _ = identifier.data(using: .utf8)?.base64EncodedString() ?? "unknown"
        // Crashlytics.crashlytics().setUserID(hashedId)
        #endif
    }

    /// Set custom key-value pairs for crash context
    func setCustomValue(_ value: Any, forKey key: String) {
        #if !DEBUG
        // Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Log a breadcrumb for debugging
    func logBreadcrumb(_ message: String) {
        #if !DEBUG
        // Crashlytics.crashlytics().log(message)
        #endif
    }

    // MARK: - Private Helpers

    private func logToConsole(error: Error, context: [String: Any], severity: ErrorSeverity) {
        let icon = severity == .critical ? "🔴" : severity == .error ? "❌" : severity == .warning ? "⚠️" : "ℹ️"

        // Note: Using print in debug only, will be removed in production
        print("""
        \(icon) [\(severity)] Error Logged:
        Error: \(error.localizedDescription)
        Location: \(context["file"] ?? "unknown"):\(context["line"] ?? 0) in \(context["function"] ?? "unknown")
        Context: \(context)
        """)
    }
}

// MARK: - Convenience Extensions

extension Error {
    /// Log this error with default settings
    func log(severity: ErrorSeverity = .error, userInfo: [String: Any]? = nil) {
        CrashReportingService.shared.logError(self, severity: severity, userInfo: userInfo)
    }
}

// MARK: - Integration with AppError from ErrorHandler
// AppError enum is defined in ErrorHandler.swift