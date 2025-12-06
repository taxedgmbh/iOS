import SwiftUI
import FirebaseCore
import UserNotifications
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationService = NotificationService.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Setup notifications
        setupNotifications(application)

        return true
    }

    // MARK: - Notification Setup
    private func setupNotifications(_ application: UIApplication) {
        // Set messaging delegate
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = notificationService
        #endif

        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = notificationService

        // Request notification permissions
        Task {
            await notificationService.requestNotificationPermission()
        }

        // Register for remote notifications
        application.registerForRemoteNotifications()

        // Setup notification categories
        setupNotificationCategories()

        print("✅ Notifications setup completed")
    }

    private func setupNotificationCategories() {
        // Document Review Actions
        let approveAction = UNNotificationAction(
            identifier: "APPROVE_ACTION",
            title: "Approve",
            options: [.foreground]
        )
        let rejectAction = UNNotificationAction(
            identifier: "REJECT_ACTION",
            title: "Reject",
            options: [.destructive]
        )
        let reviewLaterAction = UNNotificationAction(
            identifier: "REVIEW_LATER_ACTION",
            title: "Review Later",
            options: []
        )

        let documentReviewCategory = UNNotificationCategory(
            identifier: NotificationCategory.documentReview.rawValue,
            actions: [approveAction, rejectAction, reviewLaterAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Expert Message Actions
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )

        let expertMessageCategory = UNNotificationCategory(
            identifier: NotificationCategory.expertMessage.rawValue,
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            documentReviewCategory,
            expertMessageCategory
        ])
    }

    // MARK: - Remote Notification Registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ APNs device token: \(tokenString)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: - Remote Notification Handling
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle notification data
        #if canImport(FirebaseMessaging)
        Messaging.messaging().appDidReceiveMessage(userInfo)
        #endif

        print("📬 Received remote notification: \(userInfo)")

        // Process the notification
        if let aps = userInfo["aps"] as? [String: Any] {
            // Handle silent push
            if aps["content-available"] as? Int == 1 {
                // Perform background fetch
                performBackgroundFetch(userInfo: userInfo, completion: completionHandler)
            } else {
                completionHandler(.newData)
            }
        } else {
            completionHandler(.noData)
        }
    }

    private func performBackgroundFetch(userInfo: [AnyHashable: Any], completion: @escaping (UIBackgroundFetchResult) -> Void) {
        // Perform background tasks like syncing data
        Task {
            // Note: In a real implementation, you would need to get the user ID from stored credentials
            // or use a shared instance of AuthenticationService
            print("📦 Background fetch initiated")
            // For now, just return newData to indicate we processed the notification
            completion(.newData)
        }
    }
}

@main
struct TaxedGmbH_IOS: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthenticationService()
    @StateObject private var screenshotHandler = ScreenshotHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(screenshotHandler)
                .sheet(isPresented: $screenshotHandler.showBugReportSheet) {
                    if let screenshot = screenshotHandler.capturedScreenshot {
                        BugReportSheet(
                            screenshot: screenshot,
                            screenName: screenshotHandler.capturedScreenName
                        )
                        .environmentObject(authService)
                    }
                }
        }
    }
}

