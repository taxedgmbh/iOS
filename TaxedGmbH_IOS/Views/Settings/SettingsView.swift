import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showSignOutConfirmation = false
    @State private var refreshID = UUID()

    var body: some View {
        List {
            // Profile Section (HIG Compliant with LabeledContent)
            Section {
                if let user = authService.user {
                    LabeledContent {
                        Text(user.name)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("settings.profile.name".localized, systemImage: "person.fill")
                    }

                    LabeledContent {
                        Text(user.email)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("settings.profile.email".localized, systemImage: "envelope.fill")
                    }

                    if let phone = user.phone {
                        LabeledContent {
                            Text(phone)
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("settings.profile.phone".localized, systemImage: "phone.fill")
                        }
                    }

                    if let canton = user.canton {
                        LabeledContent {
                            Text(canton)
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("settings.profile.canton".localized, systemImage: "map.fill")
                        }
                    }

                    LabeledContent {
                        Text(user.role.rawValue.capitalized)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("settings.profile.role".localized, systemImage: "briefcase.fill")
                    }
                }
            } header: {
                Text("settings.profile.title".localized)
            }

            // Notifications Section (HIG Compliant)
            Section {
                Toggle(isOn: $notificationService.isNotificationEnabled) {
                    Label("settings.notifications.push".localized, systemImage: "bell.fill")
                }
                .onChange(of: notificationService.isNotificationEnabled) { _, newValue in
                    if newValue {
                        Task {
                            await notificationService.requestNotificationPermission()
                        }
                    }
                }

                NavigationLink {
                    DetailedNotificationSettingsView()
                } label: {
                    Label("settings.notifications.settings".localized, systemImage: "bell.badge.fill")
                }
            } header: {
                Text("settings.notifications.title".localized)
            } footer: {
                Text("settings.notifications.footer".localized)
            }

            // Language Section
            Section {
                NavigationLink {
                    LanguagePickerView()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("settings.language".localized)
                        Spacer()
                        HStack(spacing: 6) {
                            Text(localizationService.currentLanguage.flag)
                            Text(localizationService.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("settings.language".localized)
            }

            // Appearance Section
            Section {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(.taxedPrimary)
                        .frame(width: 24)
                    Text("settings.appearance.title".localized)
                    Spacer()
                    Picker("", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: themeManager.currentTheme) { _, newValue in
                        themeManager.setTheme(newValue)
                    }
                }
            } header: {
                Text("settings.appearance.header".localized)
            } footer: {
                Text("settings.appearance.footer".localized)
            }

            // App Information Section
            Section {
                NavigationLink {
                    AboutView_HIGCompliant()
                } label: {
                    Label("settings.app_info.about".localized, systemImage: "info.circle.fill")
                }

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("settings.app_info.privacy".localized)
                    }
                }

                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("settings.app_info.terms".localized)
                    }
                }

                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(.taxedPrimary)
                        .frame(width: 24)
                    Text("settings.app_info.version".localized)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("settings.app_info.title".localized)
            }

            // Support Section
            Section {
                NavigationLink {
                    SupportView()
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("settings.support.help".localized)
                    }
                }

                Link(destination: URL(string: "mailto:support@taxed.ch")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("settings.support.contact".localized)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.support.title".localized)
            }

            // Developer Tools Section (for testing)
            Section {
                NavigationLink {
                    CreateTestDocumentsView()
                } label: {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("Create Test Documents")
                    }
                }
            } header: {
                Text("Developer Tools")
            } footer: {
                Text("Tools for testing and development")
            }

            // Sign Out Section
            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .frame(width: 24)
                        Text("settings.signout.button".localized)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .id(localizationService.currentLanguage)
        .alert("settings.signout.alert.title".localized, isPresented: $showSignOutConfirmation) {
            Button("settings.signout.alert.cancel".localized, role: .cancel) {}
            Button("settings.signout.alert.confirm".localized, role: .destructive) {
                do {
                    try authService.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } message: {
            Text("settings.signout.alert.message".localized)
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.taxedPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("privacy.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                PolicySection(
                    title: "privacy.section1.title".localized,
                    content: "privacy.section1.content".localized
                )

                PolicySection(
                    title: "privacy.section2.title".localized,
                    content: "privacy.section2.content".localized
                )

                PolicySection(
                    title: "privacy.section3.title".localized,
                    content: "privacy.section3.content".localized
                )

                PolicySection(
                    title: "privacy.section4.title".localized,
                    content: "privacy.section4.content".localized
                )
            }
            .padding()
        }
        .navigationTitle("privacy.navigation_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("terms.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                PolicySection(
                    title: "terms.section1.title".localized,
                    content: "terms.section1.content".localized
                )

                PolicySection(
                    title: "terms.section2.title".localized,
                    content: "terms.section2.content".localized
                )

                PolicySection(
                    title: "terms.section3.title".localized,
                    content: "terms.section3.content".localized
                )

                PolicySection(
                    title: "terms.section4.title".localized,
                    content: "terms.section4.content".localized
                )
            }
            .padding()
        }
        .navigationTitle("terms.navigation_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Support View

struct SupportView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("support.faq".localized) {
                    FAQView()
                }

                Link(destination: URL(string: "https://taxed.ch/help")!) {
                    HStack {
                        Text("support.online_help".localized)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "mailto:support@taxed.ch")!) {
                    HStack {
                        Text("support.email".localized)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("support.phone".localized)
                    Spacer()
                    Text("+41 44 123 45 67")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("support.header".localized)
            } footer: {
                Text("support.footer".localized)
            }
        }
        .navigationTitle("support.navigation_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ View

struct FAQView: View {
    var body: some View {
        List {
            Section("faq.section.general".localized) {
                FAQRow(
                    question: "faq.general.how_it_works.question".localized,
                    answer: "faq.general.how_it_works.answer".localized
                )

                FAQRow(
                    question: "faq.general.is_secure.question".localized,
                    answer: "faq.general.is_secure.answer".localized
                )
            }

            Section("faq.section.documents".localized) {
                FAQRow(
                    question: "faq.documents.which_needed.question".localized,
                    answer: "faq.documents.which_needed.answer".localized
                )

                FAQRow(
                    question: "faq.documents.how_upload.question".localized,
                    answer: "faq.documents.how_upload.answer".localized
                )
            }
        }
        .navigationTitle("faq.navigation_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        } label: {
            Text(question)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AuthenticationService())
    }
}
