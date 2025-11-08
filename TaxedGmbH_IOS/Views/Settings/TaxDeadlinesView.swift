//
//  TaxDeadlinesView.swift
//  TaxedGmbH_IOS
//
//  Tax deadline tracking and reminder management
//

import SwiftUI

struct TaxDeadlinesView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var workspaceManager = WorkspaceManager.shared
    @State private var deadlineReminders = true
    @State private var weeklyReminders = false
    @State private var monthBeforeReminder = true
    @State private var twoWeeksBeforeReminder = true
    @State private var oneWeekBeforeReminder = true
    @State private var oneDayBeforeReminder = false

    private let cantonHelper = SwissCantonHelper.shared

    var currentTaxYear: Int {
        return workspaceManager.currentWorkspace?.taxYear ?? Calendar.current.component(.year, from: Date())
    }

    var taxDeadline: Date? {
        guard let cantonId = authService.user?.canton else { return nil }
        return cantonHelper.getNextTaxDeadline(forYear: currentTaxYear, cantonId: cantonId)
    }

    var daysUntilDeadline: Int? {
        guard let cantonId = authService.user?.canton else { return nil }
        return cantonHelper.getDaysUntilDeadline(forYear: currentTaxYear, cantonId: cantonId)
    }

    var deadlineStatus: DeadlineStatus {
        guard let days = daysUntilDeadline else { return .unknown }
        if days < 0 { return .overdue }
        if days <= 7 { return .urgent }
        if days <= 30 { return .upcoming }
        return .onTrack
    }

    enum DeadlineStatus {
        case onTrack, upcoming, urgent, overdue, unknown

        var color: Color {
            switch self {
            case .onTrack: return .green
            case .upcoming: return .orange
            case .urgent: return .red
            case .overdue: return .purple
            case .unknown: return .gray
            }
        }

        var icon: String {
            switch self {
            case .onTrack: return "checkmark.circle"
            case .upcoming: return "clock"
            case .urgent: return "exclamationmark.triangle"
            case .overdue: return "xmark.circle"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    var body: some View {
        List {
            // Deadline Overview
            Section {
                if let deadline = taxDeadline,
                   let cantonId = authService.user?.canton {

                    // Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: deadlineStatus.icon)
                                .font(.system(size: 40))
                                .foregroundColor(deadlineStatus.color)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                if let days = daysUntilDeadline, days >= 0 {
                                    Text("\(days)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(deadlineStatus.color)
                                    Text("settings.deadlines.days_remaining".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("settings.deadlines.overdue".localized)
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                }
                            }
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.deadlines.deadline_date".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(deadline, style: .date)
                                    .font(.body.weight(.semibold))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("settings.deadlines.canton".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(cantonHelper.getCantonDisplayName(forId: cantonId))
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("settings.deadlines.no_canton".localized)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.deadlines.overview".localized)
            }

            // Reminder Settings
            Section {
                Toggle(isOn: $deadlineReminders) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.deadlines.enable_reminders".localized)
                            Text("settings.deadlines.enable_reminders.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: deadlineReminders) { _, newValue in
                    if newValue {
                        requestNotificationPermissions()
                    }
                }
            } header: {
                Text("settings.deadlines.reminders".localized)
            } footer: {
                Text("settings.deadlines.reminders.footer".localized)
            }

            // Reminder Schedule
            if deadlineReminders {
                Section {
                    Toggle(isOn: $monthBeforeReminder) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("settings.deadlines.one_month_before".localized)
                        }
                    }

                    Toggle(isOn: $twoWeeksBeforeReminder) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("settings.deadlines.two_weeks_before".localized)
                        }
                    }

                    Toggle(isOn: $oneWeekBeforeReminder) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("settings.deadlines.one_week_before".localized)
                        }
                    }

                    Toggle(isOn: $oneDayBeforeReminder) {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("settings.deadlines.one_day_before".localized)
                        }
                    }

                    Toggle(isOn: $weeklyReminders) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.deadlines.weekly_reminders".localized)
                                Text("settings.deadlines.weekly_reminders.subtitle".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("settings.deadlines.reminder_schedule".localized)
                } footer: {
                    Text("settings.deadlines.reminder_schedule.footer".localized)
                }
            }

            // Important Dates
            Section {
                deadlineRow(
                    icon: "calendar.circle",
                    color: .blue,
                    title: "settings.deadlines.tax_year_start".localized,
                    date: Calendar.current.date(from: DateComponents(year: currentTaxYear, month: 1, day: 1))!
                )

                deadlineRow(
                    icon: "calendar.circle.fill",
                    color: .red,
                    title: "settings.deadlines.filing_deadline".localized,
                    date: taxDeadline ?? Date()
                )

                if let canton = authService.user?.canton,
                   cantonHelper.hasOnlinePortal(cantonId: canton) {
                    Button(action: {
                        if let url = cantonHelper.getPortalUrl(forCantonId: canton) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "safari")
                                .foregroundColor(.green)
                                .frame(width: 32)

                            Text("settings.deadlines.canton_portal".localized)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            } header: {
                Text("settings.deadlines.important_dates".localized)
            }
        }
        .navigationTitle("settings.deadlines.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let userId = authService.user?.id {
                await workspaceManager.loadCurrentWorkspace(userId: userId)
            }
        }
    }

    private func deadlineRow(icon: String, color: Color, title: String, date: Date) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)

            Spacer()

            Text(date, style: .date)
                .foregroundColor(.secondary)
        }
    }

    private func requestNotificationPermissions() {
        // TODO: Implement notification permission request
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("✅ Notification permission granted")
            }
        }
    }
}

#Preview {
    NavigationView {
        TaxDeadlinesView()
            .environmentObject(AuthenticationService())
    }
}
