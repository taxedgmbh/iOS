//
//  MoreView.swift
//  TaxedGmbH_IOS
//
//  Production-ready More menu with complete company information
//  Taxed GmbH, Biel/Bienne, Switzerland
//

import SwiftUI
import FirebaseStorage
import MessageUI

struct MoreView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var showSignOutAlert = false

    var body: some View {
        List {
            // Profile Section
            Section {
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 16) {
                        // Profile Avatar
                        ZStack {
                            Circle()
                                .fill(Color.taxedPrimary.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Text(authService.user?.name.prefix(1).uppercased() ?? "U")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.taxedPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.user?.name ?? "")
                                .font(.headline)

                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Account Section
            Section(header: Text("more.account.header".localized)) {
                MoreMenuItem(
                    icon: "gearshape.fill",
                    iconColor: .blue,
                    title: "more.settings".localized,
                    subtitle: "more.settings.subtitle".localized,
                    destination: AnyView(SettingsView())
                )

                MoreMenuItem(
                    icon: "paintpalette.fill",
                    iconColor: .purple,
                    title: "more.appearance".localized,
                    subtitle: "more.appearance.subtitle".localized,
                    destination: AnyView(AppearanceSettingsView())
                )

                MoreMenuItem(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "more.notifications".localized,
                    subtitle: "more.notifications.subtitle".localized,
                    destination: AnyView(NotificationSettingsView())
                )
            }

            // Tax Settings Section
            Section(header: Text("more.tax_settings.header".localized)) {
                MoreMenuItem(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: "more.tax_settings".localized,
                    subtitle: "more.tax_settings.subtitle".localized,
                    destination: AnyView(TaxSettingsView())
                )

                MoreMenuItem(
                    icon: "map.fill",
                    iconColor: .red,
                    title: "more.canton_settings".localized,
                    subtitle: "more.canton_settings.subtitle".localized,
                    destination: AnyView(CantonSettingsView())
                )

                MoreMenuItem(
                    icon: "calendar.badge.exclamationmark",
                    iconColor: .orange,
                    title: "more.tax_deadlines".localized,
                    subtitle: "more.tax_deadlines.subtitle".localized,
                    destination: AnyView(TaxDeadlinesView())
                )

                MoreMenuItem(
                    icon: "person.2.circle.fill",
                    iconColor: .green,
                    title: "more.expert_connection".localized,
                    subtitle: "more.expert_connection.subtitle".localized,
                    destination: AnyView(ExpertConnectionView())
                )
            }

            // Accessibility Section
            Section(header: Text("more.accessibility.header".localized)) {
                MoreMenuItem(
                    icon: "accessibility",
                    iconColor: .purple,
                    title: "more.accessibility".localized,
                    subtitle: "more.accessibility.subtitle".localized,
                    destination: AnyView(AccessibilitySettingsView())
                )
            }

            // Security Section
            Section(header: Text("more.security.header".localized)) {
                MoreMenuItem(
                    icon: "person.badge.key.fill",
                    iconColor: .blue,
                    title: "more.account_management".localized,
                    subtitle: "more.account_management.subtitle".localized,
                    destination: AnyView(AccountManagementView())
                )

                MoreMenuItem(
                    icon: "lock.shield.fill",
                    iconColor: .red,
                    title: "more.security".localized,
                    subtitle: "more.security.subtitle".localized,
                    destination: AnyView(SecuritySettingsView())
                )
            }

            // Data & Privacy Section
            Section(header: Text("more.data_privacy.header".localized)) {
                MoreMenuItem(
                    icon: "externaldrive.fill",
                    iconColor: .green,
                    title: "more.data_management".localized,
                    subtitle: "more.data_management.subtitle".localized,
                    destination: AnyView(DataManagementView())
                )
            }

            // Resources Section
            Section(header: Text("more.resources.header".localized)) {
                MoreMenuItem(
                    icon: "globe.europe.africa.fill",
                    iconColor: .green,
                    title: "more.expat_guide".localized,
                    subtitle: "more.expat_guide.subtitle".localized,
                    destination: AnyView(ExpatOnboardingView())
                )

                MoreMenuItem(
                    icon: "book.fill",
                    iconColor: .cyan,
                    title: "more.help".localized,
                    subtitle: "more.help.subtitle".localized,
                    destination: AnyView(HelpView())
                )

                MoreMenuItem(
                    icon: "envelope.fill",
                    iconColor: .indigo,
                    title: "more.contact".localized,
                    subtitle: "more.contact.subtitle".localized,
                    destination: AnyView(ContactView())
                )
            }

            // Feedback Section
            Section(header: Text("more.feedback.header".localized)) {
                MoreMenuItem(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "more.rate_app".localized,
                    subtitle: "more.rate_app.subtitle".localized,
                    action: rateApp
                )

                MoreMenuItem(
                    icon: "exclamationmark.bubble.fill",
                    iconColor: .orange,
                    title: "more.report_issue".localized,
                    subtitle: "more.report_issue.subtitle".localized,
                    destination: AnyView(ReportIssueView())
                )
            }

            // About Section
            Section(header: Text("more.about.header".localized)) {
                MoreMenuItem(
                    icon: "info.circle.fill",
                    iconColor: .teal,
                    title: "more.about".localized,
                    subtitle: "more.about.subtitle".localized,
                    destination: AnyView(AboutView_HIGCompliant())
                )

                MoreMenuItem(
                    icon: "shield.fill",
                    iconColor: .mint,
                    title: "more.privacy".localized,
                    subtitle: "more.privacy.subtitle".localized,
                    destination: AnyView(PrivacyView())
                )

                MoreMenuItem(
                    icon: "doc.text.fill",
                    iconColor: .brown,
                    title: "more.terms".localized,
                    subtitle: "more.terms.subtitle".localized,
                    destination: AnyView(TermsView())
                )

                HStack {
                    Text("more.version".localized)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }

            // Sign Out Section
            Section {
                Button(action: {
                    showSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)

                        Text("more.signout".localized)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle("more.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("more.signout.alert.title".localized, isPresented: $showSignOutAlert) {
            Button("more.signout.alert.cancel".localized, role: .cancel) { }
            Button("more.signout.alert.confirm".localized, role: .destructive) {
                do {
                    try authService.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } message: {
            Text("more.signout.alert.message".localized)
        }
    }

    // MARK: - Rate App Function

    private func rateApp() {
        // TODO: Replace with actual App Store ID when published
        // Format: https://apps.apple.com/app/id{APP_STORE_ID}?action=write-review
        // For now, open App Store search for Taxed
        if let url = URL(string: "https://apps.apple.com/search?term=taxed+gmbh+tax") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var destination: AnyView? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    menuContent
                }
            } else {
                Button(action: { action?() }) {
                    menuContent
                }
            }
        }
    }

    private var menuContent: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedPhone = ""

    // Address fields
    @State private var editedStreet = ""
    @State private var editedPostalCode = ""
    @State private var editedCity = ""

    // Swiss Tax fields
    @State private var editedAhvNumber = ""
    @State private var editedMunicipality = ""
    @State private var editedMunicipalityId = ""
    @State private var editedMaritalStatus: MaritalStatus? = nil
    @State private var editedNumberOfChildren = ""

    // Person 1 and Person 2 (for joint filing)
    @State private var editedPerson1Name = ""
    @State private var editedPerson1AhvNumber = ""
    @State private var editedPerson2Name = ""
    @State private var editedPerson2AhvNumber = ""

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var profileImageURL: String?
    @State private var isUploadingImage = false
    @State private var showSaveAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var exportedDataURL: IdentifiableURL?
    @State private var showShareSheet = false
    @State private var showCopiedToast = false

    var body: some View {
        Form {
            // Profile Photo Section with Completeness
            Section {
                VStack(spacing: 20) {
                    // Profile completeness indicator
                    ProfileCompletenessView(
                        completeness: calculateProfileCompleteness(),
                        isEditing: isEditing
                    )

                    // Profile Photo
                    ZStack(alignment: .bottomTrailing) {
                        // Profile Avatar with shadow
                        Group {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let imageURL = profileImageURL, !imageURL.isEmpty {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    case .failure(_):
                                        defaultAvatar
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 120, height: 120)
                                    @unknown default:
                                        defaultAvatar
                                    }
                                }
                            } else {
                                defaultAvatar
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.taxedPrimary.opacity(0.2), lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Edit Photo Button with animation
                        if isEditing {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.taxedPrimary)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.taxedPrimary.opacity(0.3), radius: 5, x: 0, y: 2)

                                    if isUploadingImage {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(isUploadingImage)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
            .listRowBackground(Color.clear)

            // Personal Information with enhanced styling
            Section {
                if isEditing {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.profile.name".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("settings.profile.name".localized, text: $editedName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                } else {
                    ProfileInfoRow(
                        label: "settings.profile.name".localized,
                        value: authService.user?.name ?? "",
                        icon: "person.fill"
                    )
                }

                ProfileInfoRow(
                    label: "settings.profile.email".localized,
                    value: authService.user?.email ?? "",
                    icon: "envelope.fill",
                    isEditable: false
                )

                if isEditing {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.profile.phone".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("settings.profile.phone".localized, text: $editedPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }
                    .padding(.vertical, 4)
                } else {
                    ProfileInfoRow(
                        label: "settings.profile.phone".localized,
                        value: authService.user?.phone ?? "",
                        icon: "phone.fill"
                    )
                }

            } header: {
                Text("profile.personal_info".localized)
            }

            // Address Information Section
            Section {
                if isEditing {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Street and Number", text: $editedStreet)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Postal Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("1234", text: $editedPostalCode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("City")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("City", text: $editedCity)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    if let street = authService.user?.street, !street.isEmpty {
                        ProfileInfoRow(
                            label: "Street",
                            value: street,
                            icon: "house.fill"
                        )
                    }

                    if let postalCode = authService.user?.postalCode, !postalCode.isEmpty,
                       let city = authService.user?.city, !city.isEmpty {
                        ProfileInfoRow(
                            label: "City",
                            value: "\(postalCode) \(city)",
                            icon: "building.2.fill"
                        )
                    }
                }
            } header: {
                Text("Address Information")
            }

            // Swiss Tax Information Section
            Section {
                // Show Person 1 and Person 2 for married/partnered couples
                let isJointFiling = editedMaritalStatus == .married || editedMaritalStatus == .registered_partnership ||
                                   authService.user?.maritalStatus == .married || authService.user?.maritalStatus == .registered_partnership

                if isJointFiling {
                    // Person 1 Information
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Person 1 - Full Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("e.g., Hans Müller", text: $editedPerson1Name)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Person 1 - AHV/AVS Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("756.1234.5678.97", text: $editedPerson1AhvNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, 4)
                    } else {
                        if let person1Name = authService.user?.person1Name, !person1Name.isEmpty {
                            ProfileInfoRow(
                                label: "Person 1 - Name",
                                value: person1Name,
                                icon: "person.fill"
                            )
                        }
                        if let person1Ahv = authService.user?.person1AhvNumber, !person1Ahv.isEmpty {
                            ProfileInfoRow(
                                label: "Person 1 - AHV/AVS",
                                value: person1Ahv,
                                icon: "number.circle.fill"
                            )
                        }
                    }

                    // Person 2 Information (Spouse/Partner)
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Person 2 - Full Name (Spouse/Partner)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("e.g., Maria Müller", text: $editedPerson2Name)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Person 2 - AHV/AVS Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("756.9876.5432.10", text: $editedPerson2AhvNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, 4)
                    } else {
                        if let person2Name = authService.user?.person2Name, !person2Name.isEmpty {
                            ProfileInfoRow(
                                label: "Person 2 - Name (Spouse/Partner)",
                                value: person2Name,
                                icon: "person.fill"
                            )
                        }
                        if let person2Ahv = authService.user?.person2AhvNumber, !person2Ahv.isEmpty {
                            ProfileInfoRow(
                                label: "Person 2 - AHV/AVS",
                                value: person2Ahv,
                                icon: "number.circle.fill"
                            )
                        }
                    }
                } else {
                    // Single filer - show single AHV field
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AHV/AVS Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("756.1234.5678.97", text: $editedPerson1AhvNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, 4)
                    } else if let person1Ahv = authService.user?.person1AhvNumber, !person1Ahv.isEmpty {
                        ProfileInfoRow(
                            label: "AHV/AVS Number",
                            value: person1Ahv,
                            icon: "number.circle.fill"
                        )
                    } else if let ahvNumber = authService.user?.ahvNumber, !ahvNumber.isEmpty {
                        // Backward compatibility with old ahvNumber field
                        ProfileInfoRow(
                            label: "AHV/AVS Number",
                            value: ahvNumber,
                            icon: "number.circle.fill"
                        )
                    }
                }

                if let canton = authService.user?.canton, !canton.isEmpty {
                    ProfileInfoRow(
                        label: "settings.profile.canton".localized,
                        value: canton,
                        icon: "mappin.circle.fill",
                        isEditable: false
                    )
                }

                if isEditing {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Municipality")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., Zurich", text: $editedMunicipality)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Municipality ID (BFS Number)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., 261", text: $editedMunicipalityId)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marital Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Marital Status", selection: $editedMaritalStatus) {
                            Text("Not specified").tag(nil as MaritalStatus?)
                            ForEach([MaritalStatus.single, .married, .divorced, .widowed, .registered_partnership], id: \.self) { status in
                                Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .tag(status as MaritalStatus?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Number of Children")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", text: $editedNumberOfChildren)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 4)
                } else {
                    if let municipality = authService.user?.municipality, !municipality.isEmpty {
                        ProfileInfoRow(
                            label: "Municipality",
                            value: municipality,
                            icon: "building.2.fill"
                        )
                    }

                    if let municipalityId = authService.user?.municipalityId, !municipalityId.isEmpty {
                        ProfileInfoRow(
                            label: "Municipality ID (BFS)",
                            value: municipalityId,
                            icon: "number.square.fill"
                        )
                    }

                    if let maritalStatus = authService.user?.maritalStatus {
                        ProfileInfoRow(
                            label: "Marital Status",
                            value: maritalStatus.rawValue.capitalized.replacingOccurrences(of: "_", with: " "),
                            icon: "heart.circle.fill"
                        )
                    }

                    if let numberOfChildren = authService.user?.numberOfChildren {
                        ProfileInfoRow(
                            label: "Number of Children",
                            value: "\(numberOfChildren)",
                            icon: "figure.and.child.holdinghands"
                        )
                    }
                }
            } header: {
                Text("Swiss Tax Information")
            } footer: {
                let isJointFiling = editedMaritalStatus == .married || editedMaritalStatus == .registered_partnership ||
                                   authService.user?.maritalStatus == .married || authService.user?.maritalStatus == .registered_partnership
                if isJointFiling {
                    Text("For married couples or registered partnerships, both Person 1 and Person 2 information is required for joint tax filing")
                        .font(.caption)
                } else {
                    Text("This information is required for accurate tax calculations and submission to Swiss authorities")
                        .font(.caption)
                }
            }

            // Account Information with copy functionality
            Section {
                ProfileInfoRow(
                    label: "settings.profile.role".localized,
                    value: authService.user?.role.rawValue.capitalized ?? "",
                    icon: "person.badge.shield.checkmark.fill",
                    isEditable: false
                )

                ProfileInfoRow(
                    label: "profile.account_created".localized,
                    value: formatAccountCreationDate(authService.user?.createdAt),
                    icon: "calendar.badge.clock",
                    isEditable: false
                )

                Button(action: {
                    copyToClipboard(authService.user?.id ?? "")
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("profile.user_id".localized)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(authService.user?.id ?? "")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: showCopiedToast ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(showCopiedToast ? .green : .gray)
                            .font(.caption)
                    }
                }
            } header: {
                Text("profile.account_info".localized)
            }

            // Preferences
            Section {
                NavigationLink(destination: LanguageSelectionView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("profile.language".localized)
                        Spacer()
                        Text(localizationService.currentLanguage.displayName)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("profile.preferences".localized)
            }

            // Data Management with enhanced buttons
            Section {
                Button(action: {
                    exportUserData()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("profile.export_data".localized)
                            .foregroundColor(.primary)
                    }
                }

                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("profile.delete_account".localized)
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("profile.data_management".localized)
            } footer: {
                Text("profile.delete_account.warning".localized)
                    .font(.caption)
            }
        }
        .navigationTitle("settings.profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }) {
                    HStack(spacing: 4) {
                        if isEditing {
                            Image(systemName: "checkmark.circle.fill")
                        } else {
                            Image(systemName: "pencil.circle.fill")
                        }
                        Text(isEditing ? "common.save".localized : "common.edit".localized)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isEditing ? .green : .taxedPrimary)
                }
            }
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("profile.saved".localized),
                message: Text("profile.saved_message".localized),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
        .alert("profile.delete_account.alert.title".localized, isPresented: $showDeleteAccountAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("profile.delete_account.confirm".localized, role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("profile.delete_account.alert.message".localized)
        }
        .sheet(item: $exportedDataURL) { identifiableURL in
            ActivityViewController(activityItems: [identifiableURL.url])
        }
        .sheet(isPresented: $showImagePicker) {
            ProfileImagePicker(image: $selectedImage) { image in
                uploadProfileImage(image)
            }
        }
        .onAppear {
            profileImageURL = authService.user?.profileImageUrl
        }
    }

    // Default avatar view
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.taxedPrimary.opacity(0.8),
                            Color.taxedPrimary.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Text(authService.user?.name.prefix(1).uppercased() ?? "U")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // Calculate profile completeness percentage
    private func calculateProfileCompleteness() -> Int {
        var completeness = 0
        var totalFields = 13  // Base fields

        if let user = authService.user {
            // Basic fields (4)
            if !user.name.isEmpty { completeness += 1 }
            if !user.email.isEmpty { completeness += 1 }
            if !(user.phone ?? "").isEmpty { completeness += 1 }
            if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty { completeness += 1 }

            // Address fields (3)
            if !(user.street ?? "").isEmpty { completeness += 1 }
            if !(user.postalCode ?? "").isEmpty { completeness += 1 }
            if !(user.city ?? "").isEmpty { completeness += 1 }

            // Check if joint filing (married or registered partnership)
            let isJointFiling = user.maritalStatus == .married || user.maritalStatus == .registered_partnership

            if isJointFiling {
                // For joint filing, we need both person 1 and person 2 info (4 fields)
                totalFields = 15  // 4 basic + 3 address + 2 person1 + 2 person2 + 4 other tax fields

                if !(user.person1Name ?? "").isEmpty { completeness += 1 }
                if !(user.person1AhvNumber ?? "").isEmpty { completeness += 1 }
                if !(user.person2Name ?? "").isEmpty { completeness += 1 }
                if !(user.person2AhvNumber ?? "").isEmpty { completeness += 1 }
            } else {
                // For single filing, just person 1 AHV (1 field)
                totalFields = 12  // 4 basic + 3 address + 1 ahv + 4 other tax fields
                if !(user.person1AhvNumber ?? "").isEmpty || !(user.ahvNumber ?? "").isEmpty {
                    completeness += 1
                }
            }

            // Common Swiss Tax fields (4)
            if user.canton != nil { completeness += 1 }
            if !(user.municipality ?? "").isEmpty { completeness += 1 }
            if user.maritalStatus != nil { completeness += 1 }
            if user.numberOfChildren != nil { completeness += 1 }
        }

        return Int((Double(completeness) / Double(totalFields)) * 100)
    }

    // Copy to clipboard function
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }

    // Upload profile image to Firebase Storage
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authService.user?.id else {
            print("❌ No user ID found")
            return
        }

        isUploadingImage = true

        Task {
            do {
                // Import Firebase Storage
                let storage = FirebaseStorage.Storage.storage()
                let storageRef = storage.reference()

                // Create a reference to the profile image
                let profileImageRef = storageRef.child("profile_images/\(userId).jpg")

                // Compress image
                guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                    throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                }

                // Upload the file
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"

                let _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)

                // Get the download URL
                let downloadURL = try await profileImageRef.downloadURL()

                // Update user profile with image URL
                try await authService.updateUser(userId: userId, data: ["profileImageUrl": downloadURL.absoluteString])

                // Update local state
                await MainActor.run {
                    profileImageURL = downloadURL.absoluteString
                    isUploadingImage = false
                    print("✅ Profile image uploaded successfully")
                }
            } catch {
                print("❌ Error uploading profile image: \(error)")
                await MainActor.run {
                    isUploadingImage = false
                    authService.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                }
            }
        }
    }

    private func startEditing() {
        editedName = authService.user?.name ?? ""
        editedPhone = authService.user?.phone ?? ""

        // Address fields
        editedStreet = authService.user?.street ?? ""
        editedPostalCode = authService.user?.postalCode ?? ""
        editedCity = authService.user?.city ?? ""

        // Swiss Tax fields
        editedAhvNumber = authService.user?.ahvNumber ?? ""
        editedMunicipality = authService.user?.municipality ?? ""
        editedMunicipalityId = authService.user?.municipalityId ?? ""
        editedMaritalStatus = authService.user?.maritalStatus
        if let numberOfChildren = authService.user?.numberOfChildren {
            editedNumberOfChildren = "\(numberOfChildren)"
        } else {
            editedNumberOfChildren = ""
        }

        // Person 1 and Person 2 fields
        editedPerson1Name = authService.user?.person1Name ?? ""
        editedPerson1AhvNumber = authService.user?.person1AhvNumber ?? (authService.user?.ahvNumber ?? "") // Backward compatibility
        editedPerson2Name = authService.user?.person2Name ?? ""
        editedPerson2AhvNumber = authService.user?.person2AhvNumber ?? ""

        isEditing = true
    }

    private func saveChanges() {
        guard let userId = authService.user?.id else {
            print("❌ No user ID found")
            return
        }

        Task {
            do {
                var updateData: [String: Any] = [:]

                // Only update changed fields
                if editedName != authService.user?.name {
                    updateData["name"] = editedName
                }

                if editedPhone != (authService.user?.phone ?? "") {
                    updateData["phone"] = editedPhone
                }

                // Address fields
                if editedStreet != (authService.user?.street ?? "") {
                    updateData["street"] = editedStreet
                }

                if editedPostalCode != (authService.user?.postalCode ?? "") {
                    updateData["postalCode"] = editedPostalCode
                }

                if editedCity != (authService.user?.city ?? "") {
                    updateData["city"] = editedCity
                }

                // Person 1 and Person 2 fields
                if editedPerson1Name != (authService.user?.person1Name ?? "") {
                    updateData["person1Name"] = editedPerson1Name
                }

                if editedPerson1AhvNumber != (authService.user?.person1AhvNumber ?? "") {
                    updateData["person1AhvNumber"] = editedPerson1AhvNumber
                }

                if editedPerson2Name != (authService.user?.person2Name ?? "") {
                    updateData["person2Name"] = editedPerson2Name
                }

                if editedPerson2AhvNumber != (authService.user?.person2AhvNumber ?? "") {
                    updateData["person2AhvNumber"] = editedPerson2AhvNumber
                }

                // Swiss Tax fields
                if editedAhvNumber != (authService.user?.ahvNumber ?? "") {
                    updateData["ahvNumber"] = editedAhvNumber
                }

                if editedMunicipality != (authService.user?.municipality ?? "") {
                    updateData["municipality"] = editedMunicipality
                }

                if editedMunicipalityId != (authService.user?.municipalityId ?? "") {
                    updateData["municipalityId"] = editedMunicipalityId
                }

                // Marital status
                if editedMaritalStatus != authService.user?.maritalStatus {
                    if let status = editedMaritalStatus {
                        updateData["maritalStatus"] = status.rawValue
                    } else {
                        updateData["maritalStatus"] = nil
                    }
                }

                // Number of children
                let numberOfChildren = Int(editedNumberOfChildren)
                if numberOfChildren != authService.user?.numberOfChildren {
                    if let count = numberOfChildren {
                        updateData["numberOfChildren"] = count
                    } else {
                        updateData["numberOfChildren"] = nil
                    }
                }

                // If there are changes, save them
                if !updateData.isEmpty {
                    try await authService.updateUser(userId: userId, data: updateData)
                    print("✅ Profile changes saved to Firestore")
                }

                // Update UI state
                await MainActor.run {
                    isEditing = false
                    showSaveAlert = true
                }
            } catch {
                print("❌ Error saving profile changes: \(error)")
                // Show error to user
                await MainActor.run {
                    authService.errorMessage = "Fehler beim Speichern der Änderungen: \(error.localizedDescription)"
                }
            }
        }
    }

    private func exportUserData() {
        guard let user = authService.user else { return }

        Task {
            do {
                // Convert user to JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601

                let jsonData = try encoder.encode(user)

                // Save to temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "taxed_user_data_\(Date().timeIntervalSince1970).json"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try jsonData.write(to: fileURL)

                // Show share sheet
                await MainActor.run {
                    exportedDataURL = IdentifiableURL(url: fileURL)
                }

                print("✅ User data exported successfully")
            } catch {
                print("❌ Error exporting user data: \(error)")
            }
        }
    }

    private func deleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
                print("✅ Account deleted successfully")
                // Navigation will happen automatically when isAuthenticated becomes false
            } catch {
                print("❌ Error deleting account: \(error)")
                await MainActor.run {
                    authService.errorMessage = "Fehler beim Löschen des Kontos: \(error.localizedDescription)"
                }
            }
        }
    }

    private func formatAccountCreationDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        // Use the current localization service language
        formatter.locale = LocalizationService.shared.currentLanguage.locale

        return formatter.string(from: date)
    }
}

// MARK: - Profile Completeness View

struct ProfileCompletenessView: View {
    let completeness: Int
    let isEditing: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(completeness) / 100)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: completeness)

                Text("\(completeness)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(progressColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("profile.completeness".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isEditing && completeness < 100 {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.taxedPrimary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }

    private var progressColor: Color {
        switch completeness {
        case 0..<50:
            return .orange
        case 50..<80:
            return .yellow
        default:
            return .green
        }
    }

    private var statusMessage: String {
        switch completeness {
        case 0..<50:
            return "profile.completeness.low".localized
        case 50..<80:
            return "profile.completeness.medium".localized
        case 80..<100:
            return "profile.completeness.high".localized
        default:
            return "profile.completeness.complete".localized
        }
    }
}

// MARK: - Profile Info Row

struct ProfileInfoRow: View {
    let label: String
    let value: String
    let icon: String
    var isEditable: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.taxedPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Spacer()

            if !isEditable {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile Image Picker

import PhotosUI

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("❌ Error loading image: \(error)")
                        return
                    }

                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.image = uiImage
                            self.parent.onImageSelected(uiImage)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - URL Wrapper for Identifiable
// Using a wrapper to avoid potential future conflicts with Foundation
struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

// URL Identifiable extension removed to avoid future conflicts with Swift/Foundation.
// Use IdentifiableURL wrapper instead if needed.

// MARK: - Activity View Controller
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Language Selection View

struct LanguageSelectionView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button(action: {
                    localizationService.setLanguage(language)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(language.flag)
                            .font(.title2)

                        Text(language.displayName)
                            .foregroundColor(.primary)

                        Spacer()

                        if localizationService.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.taxedPrimary)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("profile.language".localized)
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var documentUpdates = true
    @State private var expertMessages = true
    @State private var statusChanges = true
    @State private var deadlineReminders = true

    var body: some View {
        Form {
            Section(header: Text("settings.notifications.title".localized),
                    footer: Text("settings.notifications.detail_footer".localized)) {
                Toggle("settings.notifications.document_updates".localized, isOn: $documentUpdates)
                Toggle("settings.notifications.expert_messages".localized, isOn: $expertMessages)
                Toggle("settings.notifications.status_changes".localized, isOn: $statusChanges)
                Toggle("settings.notifications.deadline_reminders".localized, isOn: $deadlineReminders)
            }
        }
        .navigationTitle("settings.notifications.title".localized)
    }
}

// MARK: - Help View

struct HelpView: View {
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        List {
            Section(header: Text("help.common_questions".localized)) {
                NavigationLink(destination: HelpDetailView(topic: "upload")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("help.how_upload".localized)
                            .font(.body)
                        Text("help.how_upload.desc".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                NavigationLink(destination: HelpDetailView(topic: "expat")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("help.expat_taxes".localized)
                            .font(.body)
                        Text("help.expat_taxes.desc".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                NavigationLink(destination: HelpDetailView(topic: "deadline")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("help.deadlines".localized)
                            .font(.body)
                        Text("help.deadlines.desc".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Section(header: Text("help.support".localized)) {
                Link(destination: URL(string: "tel:+41799107787")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text("+41 79 910 77 87")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Link(destination: URL(string: "mailto:support@taxed.ch")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("support@taxed.ch")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("more.help".localized)
    }
}

struct HelpDetailView: View {
    let topic: String
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("help.\(topic).content".localized)
                    .padding()
            }
        }
        .navigationTitle("help.\(topic)".localized)
    }
}

// MARK: - Contact View

struct ContactView: View {
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        List {
            Section(header: Text("contact.company".localized)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Taxed GmbH")
                        .font(.headline)
                    Text("Aegertenstrasse 10")
                    Text("2503 Biel/Bienne")
                    Text("Switzerland")
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("contact.methods".localized)) {
                Link(destination: URL(string: "tel:+41799107787")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("contact.phone".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("+41 79 910 77 87")
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Link(destination: URL(string: "mailto:info@taxed.ch")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("contact.email".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("info@taxed.ch")
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Link(destination: URL(string: "https://taxed.ch")!) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("contact.website".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("taxed.ch")
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Section(header: Text("contact.hours".localized)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("contact.business_hours".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Monday - Friday: 9:00 - 18:00")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("more.contact".localized)
    }
}

#Preview {
    NavigationView {
        MoreView()
            .environmentObject(AuthenticationService())
    }
}
