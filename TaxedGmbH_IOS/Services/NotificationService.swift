//
//  NotificationService.swift
//  TaxedGmbH_IOS
//
//  Handles all notification-related functionality including push and local notifications
//

import Foundation
import UserNotifications
import SwiftUI
import Combine
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

// MARK: - Notification Categories
enum NotificationCategory: String {
    case documentReview = "DOCUMENT_REVIEW"
    case taxDeadline = "TAX_DEADLINE"
    case expertMessage = "EXPERT_MESSAGE"
    case statusUpdate = "STATUS_UPDATE"
    case reminder = "REMINDER"
}

// MARK: - Notification Service
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    // Published properties
    @Published var isNotificationEnabled = false
    @Published var fcmToken: String?
    @Published var pendingNotificationCount = 0

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        setupNotifications()
    }

    // MARK: - Setup
    private func setupNotifications() {
        center.delegate = self
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif

        // Check initial permission status
        checkNotificationStatus()
    }

    // MARK: - Permission Management
    func requestNotificationPermission() async -> Bool {
        do {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert, .provisional]
            let granted = try await center.requestAuthorization(options: authOptions)

            await MainActor.run {
                self.isNotificationEnabled = granted
            }

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }

            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    func checkNotificationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized

                if settings.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - FCM Token Management
    func updateFCMToken(_ token: String) {
        self.fcmToken = token

        // Save token to UserDefaults for persistence
        UserDefaults.standard.set(token, forKey: "fcmToken")

        // Note: In production, get user ID from stored auth state
        // For now, just log the token
        print("✅ FCM Token updated: \(token)")

        // TODO: Save token to Firestore when user is authenticated
        // This should be called from the authentication flow
    }

    private func saveFCMTokenToFirestore(userId: String, token: String) async {
        do {
            try await FirestoreService.shared.updateUserFCMToken(
                userId: userId,
                fcmToken: token,
                platform: "ios",
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            )
            print("✅ FCM token saved to Firestore")
        } catch {
            print("❌ Error saving FCM token: \(error)")
        }
    }

    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        category: NotificationCategory = .reminder,
        userInfo: [String: Any] = [:],
        trigger: UNNotificationTrigger? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: pendingNotificationCount + 1)
        content.categoryIdentifier = category.rawValue
        content.userInfo = userInfo

        // If no trigger specified, show immediately after 1 second
        let finalTrigger = trigger ?? UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: finalTrigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Local notification scheduled")
                DispatchQueue.main.async {
                    self.pendingNotificationCount += 1
                }
            }
        }
    }

    // MARK: - Document Review Notifications
    func scheduleDocumentReviewReminder(documentName: String, documentId: String, daysUntilDeadline: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Document Review Required"
        content.body = "\(documentName) needs your review. \(daysUntilDeadline) days remaining."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.documentReview.rawValue
        content.userInfo = ["documentId": documentId]

        // Schedule for tomorrow at 9 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "document_review_\(documentId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling document reminder: \(error)")
            } else {
                print("✅ Document review reminder scheduled")
            }
        }
    }

    // MARK: - Tax Deadline Notifications
    func scheduleTaxDeadlineReminder(deadlineDate: Date, taxYear: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Tax Deadline Approaching"

        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day ?? 0
        content.body = "Your \(taxYear) tax return is due in \(daysRemaining) days"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.taxDeadline.rawValue
        content.userInfo = ["taxYear": taxYear]

        // Schedule for 7 days before deadline
        let triggerDate = deadlineDate.addingTimeInterval(-7 * 24 * 60 * 60)
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "tax_deadline_\(taxYear)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling tax deadline reminder: \(error)")
            } else {
                print("✅ Tax deadline reminder scheduled")
            }
        }
    }

    // MARK: - Expert Message Notifications
    func sendExpertMessageNotification(expertName: String, messagePreview: String, conversationId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Message from \(expertName)"
        content.body = messagePreview
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.expertMessage.rawValue
        content.userInfo = ["conversationId": conversationId]

        let request = UNNotificationRequest(
            identifier: "expert_message_\(conversationId)",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error sending expert message notification: \(error)")
            } else {
                print("✅ Expert message notification sent")
            }
        }
    }

    // MARK: - Clear Notifications
    func clearAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        pendingNotificationCount = 0
        center.setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
    }

    func clearNotification(withIdentifier identifier: String) {
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        if pendingNotificationCount > 0 {
            pendingNotificationCount -= 1
        }

        // Use iOS 17.0+ API for setting badge count
        Task {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(pendingNotificationCount)
            } catch {
                print("Failed to set badge count: \(error)")
            }
        }
    }

    // MARK: - Test Notifications
    func sendTestNotification() {
        scheduleLocalNotification(
            title: "Test Notification",
            body: "This is a test notification from TaxedGmbH app. Notifications are working! 🎉",
            category: .statusUpdate,
            userInfo: ["test": true]
        )
    }

    // MARK: - Handle Deep Links
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types
        if let documentId = userInfo["documentId"] as? String {
            // Navigate to document
            navigateToDocument(documentId: documentId)
        } else if let conversationId = userInfo["conversationId"] as? String {
            // Navigate to chat
            navigateToChat(conversationId: conversationId)
        } else if let taxYear = userInfo["taxYear"] as? Int {
            // Navigate to tax process
            navigateToTaxProcess(taxYear: taxYear)
        }
    }

    private func navigateToDocument(documentId: String) {
        // Implement navigation to specific document
        print("Navigate to document: \(documentId)")
    }

    private func navigateToChat(conversationId: String) {
        // Implement navigation to chat
        print("Navigate to chat: \(conversationId)")
    }

    private func navigateToTaxProcess(taxYear: Int) {
        // Implement navigation to tax process
        print("Navigate to tax process for year: \(taxYear)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])

        // Update badge count
        pendingNotificationCount += 1
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)

        // Decrease pending count
        if pendingNotificationCount > 0 {
            pendingNotificationCount -= 1
        }

        completionHandler()
    }
}

// MARK: - MessagingDelegate
#if canImport(FirebaseMessaging)
extension NotificationService: MessagingDelegate {
    // Handle FCM token updates
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        updateFCMToken(token)
    }
}
#endif