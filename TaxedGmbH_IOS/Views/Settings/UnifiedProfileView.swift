//
//  UnifiedProfileView.swift
//  TaxedGmbH_IOS
//
//  Unified profile view combining personal info, tax settings, canton settings,
//  workspace collaboration, app settings, notifications, language, appearance,
//  app information and support in a beautiful liquid glass design
//  Apple HIG compliant with premium glass design
//

import SwiftUI

struct UnifiedProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @ObservedObject private var localizationService = LocalizationService.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // Canton Helper
    private let cantonHelper = SwissCantonHelper.shared

    // Personal Info State
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var canton: String = ""
    @State private var municipality: String = ""
    @State private var street: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""
    @State private var maritalStatus: MaritalStatus = .single
    @State private var numberOfChildren: Int = 0

    // Joint Filing (Person 1 & 2)
    @State private var person1Name: String = ""
    @State private var person1AhvNumber: String = ""
    @State private var person2Name: String = ""
    @State private var person2AhvNumber: String = ""

    // Tax Settings
    @State private var selectedTaxYear: Int = Calendar.current.component(.year, from: Date())

    // Workspace Collaboration
    @State private var inviteEmail: String = ""
    @State private var selectedWorkspaceType: WorkspaceType = .personal
    @State private var showInviteSheet: Bool = false
    @State private var showInvitations: Bool = false
    @State private var showMemberManagement: Bool = false

    // UI State
    @State private var isEditing: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showCantonPicker: Bool = false
    @State private var showSignOutConfirmation: Bool = false

    // Animation state
    @State private var sectionAppearances: [Int: Bool] = [:]

    var body: some View {
        ZStack {
            // Animated Glass Background
            AnimatedGlassBackground()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Avatar
                        profileHeader
                            .opacity(sectionAppearances[0] == true ? 1 : 0)

                        // Personal Information
                        personalInfoSection
                            .opacity(sectionAppearances[1] == true ? 1 : 0)

                        // Location & Address
                        locationSection
                            .opacity(sectionAppearances[2] == true ? 1 : 0)

                        // Tax Information
                        taxInfoSection
                            .opacity(sectionAppearances[3] == true ? 1 : 0)

                        // Joint Filing (if married/partnership)
                        if isJointFiling {
                            jointFilingSection
                                .opacity(sectionAppearances[4] == true ? 1 : 0)
                        }

                        // Tax Year
                        taxYearSection
                            .opacity(sectionAppearances[5] == true ? 1 : 0)

                        // Workspace Collaboration
                        workspaceSection
                            .opacity(sectionAppearances[6] == true ? 1 : 0)

                        // Workspace Members
                        if let workspace = workspaceManager.activeWorkspace {
                            membersSection(workspace: workspace)
                                .opacity(sectionAppearances[7] == true ? 1 : 0)
                        }

                        // Pending Invitations
                        if !workspaceManager.pendingInvitations.isEmpty {
                            invitationsSection
                                .opacity(sectionAppearances[8] == true ? 1 : 0)
                        }

                        // Divider between profile/workspace and app settings
                        sectionDivider
                            .opacity(sectionAppearances[9] == true ? 1 : 0)

                        // Notifications Settings
                        notificationsSection
                            .opacity(sectionAppearances[10] == true ? 1 : 0)

                        // Language Selection
                        languageSection
                            .opacity(sectionAppearances[11] == true ? 1 : 0)

                        // Appearance/Theme
                        appearanceSection
                            .opacity(sectionAppearances[12] == true ? 1 : 0)

                        // App Information
                        appInformationSection
                            .opacity(sectionAppearances[13] == true ? 1 : 0)

                        // Support
                        supportSection
                            .opacity(sectionAppearances[14] == true ? 1 : 0)

                        // Sign Out Button
                        signOutButton
                            .opacity(sectionAppearances[15] == true ? 1 : 0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserData()
            loadWorkspaceData()
            animateEntrance()
        }
        .sheet(isPresented: $showInviteSheet) {
            inviteSpouseSheet
        }
        .sheet(isPresented: $showCantonPicker) {
            cantonPickerSheet
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("settings.signout.alert.title".localized, isPresented: $showSignOutConfirmation) {
            Button("settings.signout.alert.cancel".localized, role: .cancel) {}
            Button("settings.signout.alert.confirm".localized, role: .destructive) {
                try? authService.signOut()
            }
        } message: {
            Text("settings.signout.alert.message".localized)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Dismiss profile view")

            Spacer()

            Text(isEditing ? "profile.edit".localized : "profile.title".localized)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button {
                if isEditing {
                    Task {
                        await saveProfile()
                    }
                } else {
                    toggleEditMode()
                }
            } label: {
                Text(isEditing ? "profile.save".localized : "profile.edit".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(isEditing ? "Save profile changes" : "Edit profile")
        }
        .padding()
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with Glass Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.6),
                                        Color.blue.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Text(getInitials())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
            .glow(color: .blue, radius: 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Profile avatar")

            VStack(spacing: 4) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.top, 20)
    }

    // MARK: - Personal Information Section

    private var personalInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.personal_info".localized,
                systemImage: "person.fill"
            )
            .foregroundColor(.blue)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ProfileField(
                    label: "profile.field.name".localized,
                    icon: "person.fill",
                    text: $name,
                    isEditing: isEditing
                )

                ProfileField(
                    label: "profile.field.email".localized,
                    icon: "envelope.fill",
                    text: $email,
                    isEditing: false // Email not editable
                )

                ProfileField(
                    label: "profile.field.phone".localized,
                    icon: "phone.fill",
                    text: $phone,
                    isEditing: isEditing
                )
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .blue.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.location".localized,
                systemImage: "location.fill"
            )
            .foregroundColor(.green)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // Canton Picker Button
                Button {
                    showCantonPicker = true
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)

                        Text(canton.isEmpty ? "profile.field.select_canton".localized : cantonHelper.getCantonDisplayName(forId: canton))
                            .foregroundColor(canton.isEmpty ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .frame(minHeight: 44)
                    .padding(16)
                }
                .glassCard(cornerRadius: 16, borderColor: .green.opacity(0.2))
                .disabled(!isEditing)
                .accessibilityLabel(canton.isEmpty ? "Select canton" : "Canton: \(cantonHelper.getCantonDisplayName(forId: canton))")
                .accessibilityHint(isEditing ? "Tap to change canton" : "")

                ProfileField(
                    label: "profile.field.municipality".localized,
                    icon: "building.2.fill",
                    text: $municipality,
                    isEditing: isEditing
                )

                ProfileField(
                    label: "profile.field.street".localized,
                    icon: "signpost.right.fill",
                    text: $street,
                    isEditing: isEditing
                )

                HStack(spacing: 12) {
                    ProfileField(
                        label: "profile.field.postal_code".localized,
                        icon: "envelope.fill",
                        text: $postalCode,
                        isEditing: isEditing
                    )

                    ProfileField(
                        label: "profile.field.city".localized,
                        icon: "building.2.fill",
                        text: $city,
                        isEditing: isEditing
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .green.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Tax Information Section

    private var taxInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.tax_info".localized,
                systemImage: "doc.text.fill"
            )
            .foregroundColor(.orange)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // Marital Status Picker
                if isEditing {
                    Picker("profile.field.marital_status".localized, selection: $maritalStatus) {
                        Text("marital_status.single".localized).tag(MaritalStatus.single)
                        Text("marital_status.married".localized).tag(MaritalStatus.married)
                        Text("marital_status.divorced".localized).tag(MaritalStatus.divorced)
                        Text("marital_status.widowed".localized).tag(MaritalStatus.widowed)
                        Text("marital_status.registered_partnership".localized).tag(MaritalStatus.registered_partnership)
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 44)
                    .padding(4)
                    .glassCard(cornerRadius: 12, borderColor: .orange.opacity(0.2))
                    .accessibilityLabel("Marital status: \(maritalStatusDisplayName)")
                } else {
                    ProfileInfoRow(
                        icon: "heart.fill",
                        label: "profile.field.marital_status".localized,
                        value: "marital_status.\(maritalStatus.rawValue)".localized,
                        color: .orange
                    )
                }

                // Number of Children
                ProfileInfoRow(
                    icon: "figure.2.and.child.holdinghands",
                    label: "profile.field.children".localized,
                    value: "\(numberOfChildren)",
                    color: .orange
                )
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .orange.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Joint Filing Section

    private var jointFilingSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.joint_filing".localized,
                systemImage: "person.2.fill"
            )
            .foregroundColor(.purple)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                Text("profile.joint_filing.person1".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                ProfileField(
                    label: "profile.field.name".localized,
                    icon: "person.fill",
                    text: $person1Name,
                    isEditing: isEditing
                )

                ProfileField(
                    label: "profile.joint_filing.ahv".localized,
                    icon: "number",
                    text: $person1AhvNumber,
                    isEditing: isEditing
                )

                Divider()
                    .padding(.vertical, 8)

                Text("profile.joint_filing.person2".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                ProfileField(
                    label: "profile.field.name".localized,
                    icon: "person.fill",
                    text: $person2Name,
                    isEditing: isEditing
                )

                ProfileField(
                    label: "profile.joint_filing.ahv".localized,
                    icon: "number",
                    text: $person2AhvNumber,
                    isEditing: isEditing
                )
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .purple.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Tax Year Section

    private var taxYearSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.tax_year".localized,
                systemImage: "calendar"
            )
            .foregroundColor(.indigo)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                Picker("profile.section.tax_year".localized, selection: $selectedTaxYear) {
                    ForEach(taxYearOptions, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight: 44)
                .onChange(of: selectedTaxYear) { _, newYear in
                    Task {
                        await changeTaxYear(to: newYear)
                    }
                }
                .accessibilityLabel("Tax year: \(selectedTaxYear)")

                if let workspace = workspaceManager.activeWorkspace {
                    ProfileInfoRow(
                        icon: "folder.fill",
                        label: "profile.field.workspace".localized,
                        value: workspace.name,
                        color: .indigo
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .indigo.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Workspace Section

    private var workspaceSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "profile.section.collaboration".localized,
                systemImage: "person.2.fill"
            )
            .foregroundColor(.pink)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // Workspace Type Picker
                if isEditing, let workspace = workspaceManager.activeWorkspace {
                    if workspace.ownerId == authService.user?.id {
                        Picker("profile.collaboration.type".localized, selection: $selectedWorkspaceType) {
                            Text("profile.collaboration.type.personal".localized).tag(WorkspaceType.personal)
                            Text("profile.collaboration.type.joint".localized).tag(WorkspaceType.joint)
                            Text("profile.collaboration.type.family".localized).tag(WorkspaceType.family)
                            Text("profile.collaboration.type.business".localized).tag(WorkspaceType.business)
                        }
                        .pickerStyle(.menu)
                        .frame(minHeight: 44)
                        .padding(4)
                        .glassCard(cornerRadius: 12, borderColor: .pink.opacity(0.2))
                        .onChange(of: selectedWorkspaceType) { _, newType in
                            Task {
                                await updateWorkspaceType(to: newType)
                            }
                        }
                        .accessibilityLabel("Workspace type: \(workspaceTypeDisplayName)")
                    }
                }

                // Invite Spouse/Partner Button
                if canInviteMembers {
                    Button {
                        showInviteSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.pink)

                            Text("profile.collaboration.invite_button".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .frame(minHeight: 44)
                        .padding(16)
                    }
                    .glassCard(cornerRadius: 16, borderColor: .pink.opacity(0.3), glowColor: .pink.opacity(0.1))
                    .accessibilityLabel("Invite spouse or partner")
                    .accessibilityHint("Opens invitation form")
                }

                // Info about collaboration
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.pink.opacity(0.8))
                        .font(.caption)

                    Text("profile.collaboration.info".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .pink.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Members Section

    private func membersSection(workspace: Workspace) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.cyan)
                Text("profile.section.members".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(workspace.members.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Workspace members: \(workspace.members.count)")
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(workspace.members) { member in
                    MemberRow(
                        member: member,
                        isOwner: member.userId == workspace.ownerId,
                        canRemove: canRemoveMember(member, from: workspace),
                        onRemove: {
                            Task {
                                await removeMember(member, from: workspace)
                            }
                        }
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .cyan.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Invitations Section

    private var invitationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                SectionHeaderView(
                    title: "profile.section.invitations".localized,
                    systemImage: "envelope.badge.fill"
                )
                .foregroundColor(.yellow)

                Spacer()

                Text("\(workspaceManager.pendingInvitations.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pending invitations: \(workspaceManager.pendingInvitations.count)")
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(workspaceManager.pendingInvitations) { invitation in
                    InvitationRow(
                        invitation: invitation,
                        onAccept: {
                            Task {
                                await acceptInvitation(invitation)
                            }
                        },
                        onDecline: {
                            Task {
                                await declineInvitation(invitation)
                            }
                        }
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .yellow.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        HStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .secondary.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "settings.notifications.title".localized,
                systemImage: "bell.fill"
            )
            .foregroundColor(.orange)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // Push Notifications Toggle
                GlassToggleRow(
                    icon: "bell.fill",
                    title: "settings.notifications.push".localized,
                    isOn: $notificationService.isNotificationEnabled,
                    color: .orange
                )
                .onChange(of: notificationService.isNotificationEnabled) { _, newValue in
                    if newValue {
                        Task {
                            await notificationService.requestNotificationPermission()
                        }
                    }
                }

                // Navigation to Detailed Notification Settings
                NavigationLink(destination: DetailedNotificationSettingsView()) {
                    GlassNavigationRow(
                        icon: "bell.badge.fill",
                        title: "settings.notifications.settings".localized,
                        color: .orange
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .orange.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Language Section

    private var languageSection: some View {
        NavigationLink(destination: LanguagePickerView()) {
            VStack(spacing: 16) {
                SectionHeaderView(
                    title: "settings.language".localized,
                    systemImage: "globe"
                )
                .foregroundColor(.blue)
                .accessibilityAddTraits(.isHeader)

                HStack {
                    Text(localizationService.currentLanguage.flag)
                        .font(.largeTitle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationService.currentLanguage.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("settings.language.current".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 44)
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .blue.opacity(0.2))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Language: \(localizationService.currentLanguage.displayName)")
        .accessibilityHint("Tap to change language")
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "settings.appearance.title".localized,
                systemImage: "circle.lefthalf.filled"
            )
            .foregroundColor(.purple)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeOptionButton(theme: theme)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .purple.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    private func themeOptionButton(theme: AppTheme) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                themeManager.setTheme(theme)
            }
        } label: {
            HStack {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(theme == themeManager.currentTheme ? .purple : .secondary)
                    .frame(width: 44, height: 44)
                    .background(theme == themeManager.currentTheme ? Color.purple.opacity(0.15) : Color.clear)
                    .cornerRadius(10)

                Text(theme.displayName)
                    .font(.subheadline)
                    .fontWeight(theme == themeManager.currentTheme ? .semibold : .regular)
                    .foregroundColor(.primary)

                Spacer()

                if theme == themeManager.currentTheme {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            .frame(minHeight: 44)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(theme == themeManager.currentTheme ? [.isSelected] : [])
    }

    // MARK: - App Information Section

    private var appInformationSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "settings.app_info.title".localized,
                systemImage: "info.circle.fill"
            )
            .foregroundColor(.teal)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // About
                NavigationLink(destination: AboutView_HIGCompliant()) {
                    GlassNavigationRow(
                        icon: "info.circle.fill",
                        title: "settings.app_info.about".localized,
                        color: .teal
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Privacy
                NavigationLink(destination: PrivacyView()) {
                    GlassNavigationRow(
                        icon: "hand.raised.fill",
                        title: "settings.app_info.privacy".localized,
                        color: .teal
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Terms
                NavigationLink(destination: TermsView()) {
                    GlassNavigationRow(
                        icon: "doc.text.fill",
                        title: "settings.app_info.terms".localized,
                        color: .teal
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Version
                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(.teal)
                        .frame(width: 24)

                    Text("settings.app_info.version".localized)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 44)
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("App version 1.0.0")
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .teal.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "settings.support.title".localized,
                systemImage: "questionmark.circle.fill"
            )
            .foregroundColor(.mint)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // Help/FAQ
                NavigationLink(destination: SupportView()) {
                    GlassNavigationRow(
                        icon: "questionmark.circle.fill",
                        title: "settings.support.help".localized,
                        color: .mint
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Contact Support
                Link(destination: URL(string: "mailto:support@taxed.ch")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.mint)
                            .frame(width: 24)

                        Text("settings.support.contact".localized)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(minHeight: 44)
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Contact support via email")
                .accessibilityHint("Opens email client")
            }
            .padding(20)
            .glassCard(cornerRadius: 20, borderColor: .mint.opacity(0.2))
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                Text("profile.sign_out".localized)
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
        }
        .glassCard(cornerRadius: 16, borderColor: .red.opacity(0.3))
        .padding(.top, 20)
        .accessibilityLabel("Sign out")
        .accessibilityHint("Sign out of your account")
    }

    // MARK: - Invite Spouse Sheet

    private var inviteSpouseSheet: some View {
        ZStack {
            AnimatedGlassBackground()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.pink)
                        .glow(color: .pink, radius: 20)

                    Text("profile.invite.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("profile.invite.subtitle".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .accessibilityElement(children: .combine)

                // Email Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("profile.invite.email_label".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    GlassTextField(
                        text: $inviteEmail,
                        placeholder: "profile.invite.email_placeholder".localized,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    .autocapitalization(.none)
                }
                .padding(20)
                .glassCard(cornerRadius: 20, borderColor: .pink.opacity(0.2))

                // Send Invitation Button
                Button {
                    Task {
                        await sendInvitation()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("profile.invite.send_button".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(
                        LinearGradient(
                            colors: [.pink, .pink.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .pink.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .disabled(inviteEmail.isEmpty || isLoading)
                .accessibilityLabel("Send invitation")

                // Cancel Button
                Button {
                    showInviteSheet = false
                    inviteEmail = ""
                } label: {
                    Text("common.cancel".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(minHeight: 44)
                }
                .accessibilityLabel("Cancel invitation")

                Spacer()
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Canton Picker Sheet

    private var cantonPickerSheet: some View {
        NavigationView {
            ZStack {
                AnimatedGlassBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(cantonHelper.allCantons) { cantonItem in
                            Button {
                                self.canton = cantonItem.id
                                showCantonPicker = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cantonItem.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text(cantonItem.id.uppercased())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if self.canton == cantonItem.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .frame(minHeight: 44)
                                .padding(16)
                            }
                            .glassCard(
                                cornerRadius: 16,
                                borderColor: self.canton == cantonItem.id ? .green.opacity(0.3) : .white.opacity(0.2)
                            )
                            .accessibilityLabel("\(cantonItem.displayName), \(cantonItem.id.uppercased())")
                            .accessibilityAddTraits(self.canton == cantonItem.id ? [.isSelected] : [])
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("profile.field.select_canton".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        showCantonPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var isJointFiling: Bool {
        maritalStatus == .married || maritalStatus == .registered_partnership
    }

    private var taxYearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1))
    }

    private var canInviteMembers: Bool {
        guard let workspace = workspaceManager.activeWorkspace,
              let userId = authService.user?.id else {
            return false
        }
        return workspace.hasAdminAccess(userId: userId)
    }

    private var maritalStatusDisplayName: String {
        return "marital_status.\(maritalStatus.rawValue)".localized
    }

    private var workspaceTypeDisplayName: String {
        return "profile.collaboration.type.\(selectedWorkspaceType.rawValue)".localized
    }

    private func canRemoveMember(_ member: WorkspaceMember, from workspace: Workspace) -> Bool {
        guard let userId = authService.user?.id else { return false }

        // Can't remove owner
        if member.userId == workspace.ownerId {
            return false
        }

        // Can't remove yourself
        if member.userId == userId {
            return false
        }

        // Must have admin access
        return workspace.hasAdminAccess(userId: userId)
    }

    private func getInitials() -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }

    // MARK: - Data Loading

    private func loadUserData() {
        guard let user = authService.user else { return }

        name = user.name
        email = user.email
        phone = user.phone ?? ""
        canton = user.canton ?? ""
        municipality = user.municipality ?? ""
        street = user.street ?? ""
        postalCode = user.postalCode ?? ""
        city = user.city ?? ""
        maritalStatus = user.maritalStatus ?? .single
        numberOfChildren = user.numberOfChildren ?? 0

        person1Name = user.person1Name ?? ""
        person1AhvNumber = user.person1AhvNumber ?? ""
        person2Name = user.person2Name ?? ""
        person2AhvNumber = user.person2AhvNumber ?? ""
    }

    private func loadWorkspaceData() {
        guard let userId = authService.user?.id else { return }

        Task {
            do {
                // Load workspaces
                try await workspaceManager.loadUserWorkspaces(for: userId)

                // Load pending invitations
                try await workspaceManager.loadPendingInvitations(for: email)

                // Set selected tax year and workspace type
                if let workspace = workspaceManager.activeWorkspace {
                    selectedTaxYear = workspace.taxYear
                    selectedWorkspaceType = workspace.type
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Animations

    private func animateEntrance() {
        guard !reduceMotion else {
            // If Reduce Motion is enabled, show all sections immediately
            for i in 0...15 {
                sectionAppearances[i] = true
            }
            return
        }

        // Stagger section appearances
        for i in 0...15 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    sectionAppearances[i] = true
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleEditMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isEditing.toggle()
        }
    }

    private func saveProfile() async {
        guard let userId = authService.user?.id else { return }

        isLoading = true

        do {
            // Update user document in Firestore
            let updates: [String: Any?] = [
                "phone": phone.isEmpty ? nil : phone,
                "canton": canton.isEmpty ? nil : canton,
                "municipality": municipality.isEmpty ? nil : municipality,
                "street": street.isEmpty ? nil : street,
                "postalCode": postalCode.isEmpty ? nil : postalCode,
                "city": city.isEmpty ? nil : city,
                "maritalStatus": maritalStatus.rawValue,
                "numberOfChildren": numberOfChildren,
                "person1Name": person1Name.isEmpty ? nil : person1Name,
                "person1AhvNumber": person1AhvNumber.isEmpty ? nil : person1AhvNumber,
                "person2Name": person2Name.isEmpty ? nil : person2Name,
                "person2AhvNumber": person2AhvNumber.isEmpty ? nil : person2AhvNumber,
                "updatedAt": Date()
            ]

            try await authService.updateUser(userId: userId, data: updates.compactMapValues { $0 })

            withAnimation {
                isEditing = false
                successMessage = "profile.updated_success".localized
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func changeTaxYear(to year: Int) async {
        guard var workspace = workspaceManager.activeWorkspace else { return }

        workspace.taxYear = year

        do {
            try await workspaceManager.updateWorkspace(workspace)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateWorkspaceType(to type: WorkspaceType) async {
        guard var workspace = workspaceManager.activeWorkspace else { return }

        workspace = Workspace(
            id: workspace.id,
            name: workspace.name,
            type: type,
            ownerId: workspace.ownerId,
            members: workspace.members,
            taxYear: workspace.taxYear,
            description: workspace.description,
            isActive: workspace.isActive,
            createdAt: workspace.createdAt,
            updatedAt: Date()
        )

        do {
            try await workspaceManager.updateWorkspace(workspace)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendInvitation() async {
        guard let workspace = workspaceManager.activeWorkspace,
              let user = authService.user else {
            return
        }

        isLoading = true

        do {
            _ = try await workspaceManager.inviteMember(
                to: workspace,
                email: inviteEmail.lowercased(),
                role: .member,
                invitedBy: user
            )

            showInviteSheet = false
            inviteEmail = ""
            successMessage = "profile.invitation_sent".localized
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func acceptInvitation(_ invitation: WorkspaceInvitation) async {
        guard let user = authService.user else { return }

        isLoading = true

        do {
            try await workspaceManager.acceptInvitation(invitation, user: user)
            successMessage = "profile.invitation_accepted".localized
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func declineInvitation(_ invitation: WorkspaceInvitation) async {
        isLoading = true

        do {
            try await workspaceManager.declineInvitation(invitation)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func removeMember(_ member: WorkspaceMember, from workspace: Workspace) async {
        guard let user = authService.user else { return }

        isLoading = true

        do {
            try await workspaceManager.removeMember(
                userId: member.userId,
                from: workspace,
                removedBy: user
            )

            // Reload workspaces
            if let userId = user.id {
                try await workspaceManager.loadUserWorkspaces(for: userId)
            }

            successMessage = "profile.member_removed".localized
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Supporting Views

struct ProfileField: View {
    let label: String
    let icon: String
    @Binding var text: String
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                if isEditing {
                    TextField(label, text: $text)
                        .foregroundColor(.primary)
                        .accessibilityLabel(label)
                        .accessibilityValue(text.isEmpty ? "Empty" : text)
                } else {
                    Text(text.isEmpty ? "-" : text)
                        .foregroundColor(text.isEmpty ? .secondary : .primary)
                }
            }
            .frame(minHeight: 44)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .accessibilityElement(children: isEditing ? .contain : .combine)
        .accessibilityLabel(isEditing ? "" : "\(label): \(text.isEmpty ? "Not set" : text)")
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .frame(minHeight: 44)
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct MemberRow: View {
    let member: WorkspaceMember
    let isOwner: Bool
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(getInitials())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Role Badge
            Text(isOwner ? "profile.members.owner".localized : "profile.members.\(member.role.rawValue)".localized)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isOwner ? .blue : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isOwner ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.2))
                .cornerRadius(8)

            // Remove Button
            if canRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Remove \(member.name)")
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
    }

    private func getInitials() -> String {
        let components = member.name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }
}

struct InvitationRow: View {
    let invitation: WorkspaceInvitation
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.badge.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.workspaceName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(String(format: "profile.invitation.from".localized, invitation.invitedByName))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Invitation to \(invitation.workspaceName) from \(invitation.invitedByName)")

            HStack(spacing: 12) {
                Button {
                    onAccept()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("profile.invitation.accept".localized)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .accessibilityLabel("Accept invitation")

                Button {
                    onDecline()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("profile.invitation.decline".localized)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Decline invitation")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Glass UI Helper Components

struct GlassToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .frame(minHeight: 44)
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityLabel("\(title): \(isOn ? "Enabled" : "Disabled")")
        .accessibilityAddTraits(.isButton)
    }
}

struct GlassNavigationRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minHeight: 44)
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to navigate")
    }
}

// MARK: - Preview

#Preview {
    UnifiedProfileView()
        .environmentObject(AuthenticationService())
}
