//
//  NotificationSettingsView.swift
//  TaxedGmbH_IOS
//
//  Notification settings and preferences
//

import SwiftUI

struct NotificationSettingsView: View {
    @State private var enableReminders = true
    @State private var deadlineNotifications = true
    @State private var documentUpdates = true
    @State private var expertMessages = true

    var body: some View {
        Form {
            Section(header: Text("settings.deadlines.reminders".localized)) {
                Toggle("settings.deadlines.enable_reminders".localized, isOn: $enableReminders)
                Toggle("settings.deadlines.filing_deadline".localized, isOn: $deadlineNotifications)
            }

            Section(header: Text("settings.documents.header".localized)) {
                Toggle("Documents Updates", isOn: $documentUpdates)
            }

            Section(header: Text("settings.expert.chat".localized)) {
                Toggle("Expert Messages", isOn: $expertMessages)
            }
        }
        .navigationTitle("more.notifications".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
