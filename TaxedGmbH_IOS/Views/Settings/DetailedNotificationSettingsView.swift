//
//  DetailedNotificationSettingsView.swift
//  TaxedGmbH_IOS
//
//  Detailed notification preferences and management
//

import SwiftUI
import UserNotifications

struct DetailedNotificationSettingsView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @EnvironmentObject var authService: AuthenticationService

    // Notification preferences
    @AppStorage("notifications.documents") private var documentNotifications = true
    @AppStorage("notifications.deadlines") private var deadlineNotifications = true
    @AppStorage("notifications.messages") private var messageNotifications = true
    @AppStorage("notifications.updates") private var statusUpdateNotifications = true
    @AppStorage("notifications.reminders") private var reminderNotifications = true
    @AppStorage("notifications.sound") private var notificationSound = true
    @AppStorage("notifications.badge") private var showBadge = true

    @State private var showPermissionAlert = false
    @State private var showTestNotificationSent = false

    var body: some View {
        Form {
            // Permission Status Section
            Section {
                HStack {
                    Image(systemName: notificationService.isNotificationEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notificationService.isNotificationEnabled ? .green : .red)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notificationService.isNotificationEnabled ? "Notifications Enabled" : "Notifications Disabled")
                            .font(.headline)

                        Text(notificationService.isNotificationEnabled ?
                             "You will receive notifications from TaxedGmbH" :
                             "Enable notifications to stay updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !notificationService.isNotificationEnabled {
                        Button("Enable") {
                            requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.taxedPrimary)
                    }
                }
                .padding(.vertical, 8)

                if notificationService.fcmToken != nil {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.taxedPrimary)
                            .font(.caption)
                        Text("Push token registered")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Notification Status")
            } footer: {
                Text("Notifications must be enabled in your device settings to receive alerts")
            }

            // Notification Types Section
            Section {
                NotificationToggle(
                    title: "Document Reviews",
                    subtitle: "Get notified when documents need review",
                    icon: "doc.badge.clock",
                    isOn: $documentNotifications
                )

                NotificationToggle(
                    title: "Tax Deadlines",
                    subtitle: "Important tax deadline reminders",
                    icon: "calendar.badge.exclamationmark",
                    isOn: $deadlineNotifications
                )

                NotificationToggle(
                    title: "Expert Messages",
                    subtitle: "New messages from your tax expert",
                    icon: "message.badge",
                    isOn: $messageNotifications
                )

                NotificationToggle(
                    title: "Status Updates",
                    subtitle: "Updates on your tax filing progress",
                    icon: "arrow.triangle.2.circlepath",
                    isOn: $statusUpdateNotifications
                )

                NotificationToggle(
                    title: "Reminders",
                    subtitle: "General reminders and tips",
                    icon: "bell.badge",
                    isOn: $reminderNotifications
                )
            } header: {
                Text("Notification Types")
            } footer: {
                Text("Choose which types of notifications you want to receive")
            }

            // Notification Settings Section
            Section {
                Toggle(isOn: $notificationSound) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("Sound")
                            Text("Play sound for notifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $showBadge) {
                    HStack {
                        Image(systemName: "app.badge.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("Badge App Icon")
                            Text("Show number on app icon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Notification Settings")
            }

            // Test Notification Section
            Section {
                Button(action: sendTestNotification) {
                    HStack {
                        Image(systemName: "bell.and.waves.left.and.right")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("Send Test Notification")
                            .foregroundColor(.primary)
                        Spacer()
                        if showTestNotificationSent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.scale)
                        }
                    }
                }

                Button(action: clearAllNotifications) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Clear All Notifications")
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("Actions")
            } footer: {
                Text("Test your notification settings or clear pending notifications")
            }

            // Schedule Examples Section
            Section {
                ScheduleExampleRow(
                    title: "Morning Review",
                    time: "9:00 AM",
                    frequency: "Daily",
                    icon: "sun.max.fill",
                    color: .orange
                )

                ScheduleExampleRow(
                    title: "Tax Deadline",
                    time: "7 days before",
                    frequency: "Once",
                    icon: "calendar",
                    color: .red
                )

                ScheduleExampleRow(
                    title: "Expert Messages",
                    time: "Instant",
                    frequency: "As received",
                    icon: "bubble.left.fill",
                    color: .blue
                )
            } header: {
                Text("Notification Schedule")
            } footer: {
                Text("Examples of when you'll receive notifications")
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationService.checkNotificationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in your device settings to receive updates from TaxedGmbH")
        }
    }

    // MARK: - Methods

    private func requestNotificationPermission() {
        Task {
            let granted = await notificationService.requestNotificationPermission()
            if !granted {
                showPermissionAlert = true
            }
        }
    }

    private func sendTestNotification() {
        notificationService.sendTestNotification()

        withAnimation {
            showTestNotificationSent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showTestNotificationSent = false
            }
        }
    }

    private func clearAllNotifications() {
        notificationService.clearAllNotifications()
    }
}

// MARK: - Supporting Views

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.taxedPrimary)
                    .frame(width: 24)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ScheduleExampleRow: View {
    let title: String
    let time: String
    let frequency: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text("\(time) • \(frequency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    DetailedNotificationSettingsView()
}