//
//  ProfileView.swift
//  TaxedGmbH_IOS
//
//  User profile management: personal information, canton, municipality
//

import SwiftUI
import FirebaseFirestore

// MARK: - Custom TextField Style for Consistent Height
struct ProfileTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(minHeight: 44) // Apple HIG minimum touch target
    }
}

extension View {
    func profileTextField() -> some View {
        modifier(ProfileTextFieldStyle())
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared
    @ObservedObject private var workspaceManager = WorkspaceManager.shared
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var selectedCanton: String?
    @State private var showCantonPicker = false
    @State private var municipality: String = ""
    @State private var municipalityId: String = ""

    // Address fields
    @State private var street: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""

    // Tax Information fields
    @State private var maritalStatus: MaritalStatus?
    @State private var numberOfChildren: Int = 0
    @State private var showMaritalStatusPicker = false

    // Tax Year & Workspace fields
    @State private var showYearPicker = false
    @State private var isLoadingWorkspace = true

    // Person 1 & Person 2 fields (for joint filing)
    @State private var person1Name: String = ""
    @State private var person1AhvNumber: String = ""
    @State private var person2Name: String = ""
    @State private var person2AhvNumber: String = ""

    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isEditing = false
    @State private var isSaving = false

    private let cantonHelper = SwissCantonHelper.shared

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1)).reversed()
    }

    var body: some View {
        Form {
            // Profile Header with Glass Effect
            Section {
                GlassCard(thickness: .regular, tintColor: .blue) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)

                            Text(authService.user?.name.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text(authService.user?.name ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let canton = authService.user?.canton {
                                HStack(spacing: .paddingExtraTight) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text(cantonHelper.getCantonDisplayName(forId: canton))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, .paddingTight)

                        Spacer()
                    }
                    .padding(.paddingRelaxed)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: .paddingTight, leading: .paddingRelaxed, bottom: .paddingTight, trailing: .paddingRelaxed))

            // Personal Information
            Section {
                // Name Field
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        TextField("profile.name".localized, text: $name)
                            .profileTextField()
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.name".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(authService.user?.name ?? "")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)

                // Email Field (read-only)
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.orange)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.email".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(authService.user?.email ?? "")
                            .font(.body)
                        if authService.user?.emailVerified == true {
                            Label("profile.email_verified".localized, systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 44)

                // Phone Field
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        TextField("profile.phone".localized, text: $phone)
                            .keyboardType(.phonePad)
                            .profileTextField()
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.phone".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(authService.user?.phone?.isEmpty == false ? authService.user!.phone! : "profile.phone.not_set".localized)
                                .font(.body)
                                .foregroundColor(authService.user?.phone?.isEmpty == false ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)
            } header: {
                HStack {
                    Text("profile.personal_info".localized)
                    Spacer()
                    Button(action: toggleEditMode) {
                        Text(isEditing ? "profile.done".localized : "profile.edit".localized)
                            .font(.subheadline)
                            .foregroundColor(.taxedPrimary)
                    }
                }
            }

            // Location Information
            Section {
                // Canton Selection
                Button(action: {
                    showCantonPicker = true
                }) {
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.red)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.canton".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                if let canton = authService.user?.canton {
                                    Text(cantonHelper.getCantonDisplayName(forId: canton))
                                        .foregroundColor(.primary)

                                    // Show canton abbreviation
                                    Text("(\(canton))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("profile.canton.not_set".localized)
                                        .foregroundColor(.orange)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityHint("profile.canton.accessibility_hint".localized)
                    }
                    .frame(minHeight: 44)
                }

                // Municipality Field
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.purple)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        VStack(alignment: .leading, spacing: .paddingStandard) {
                            TextField("profile.municipality".localized, text: $municipality)
                                .profileTextField()

                            TextField("profile.municipality_id".localized, text: $municipalityId)
                                .keyboardType(.numberPad)
                                .profileTextField()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.municipality".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let municipality = authService.user?.municipality {
                                Text(municipality)
                                    .font(.body)

                                if let municipalityId = authService.user?.municipalityId {
                                    Text("ID: \(municipalityId)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("profile.municipality.not_set".localized)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)

                // Canton-specific information
                if let cantonId = authService.user?.canton,
                   let canton = cantonHelper.getCanton(byId: cantonId) {

                    // Tax Deadline Info
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.canton.tax_deadline".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(canton.taxDeadline)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)

                    // Online Portal Link
                    if canton.hasOnlinePortal {
                        Button(action: {
                            if let url = canton.portalUrl.flatMap(URL.init) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(alignment: .center, spacing: .paddingStandard) {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                    .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                                    .font(.system(size: 18))

                                Text("profile.canton.online_portal".localized)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }
            } header: {
                Text("profile.location".localized)
            } footer: {
                Text("profile.location.footer".localized)
            }

            // Address Information
            Section {
                // Street
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        TextField("profile.street".localized, text: $street)
                            .profileTextField()
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.street".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(authService.user?.street?.isEmpty == false ? authService.user!.street! : "profile.street.not_set".localized)
                                .font(.body)
                                .foregroundColor(authService.user?.street?.isEmpty == false ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)

                // Postal Code & City
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.purple)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        VStack(alignment: .leading, spacing: .paddingStandard) {
                            TextField("profile.postal_code".localized, text: $postalCode)
                                .keyboardType(.numberPad)
                                .profileTextField()

                            TextField("profile.city".localized, text: $city)
                                .profileTextField()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.postal_code_city".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let postalCode = authService.user?.postalCode, let city = authService.user?.city {
                                Text("\(postalCode) \(city)")
                                    .font(.body)
                            } else {
                                Text("profile.postal_code_city.not_set".localized)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)
            } header: {
                Text("profile.address".localized)
            }

            // Tax Information
            Section {
                // Marital Status
                Button(action: {
                    if isEditing {
                        showMaritalStatusPicker = true
                    }
                }) {
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(.red)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.marital_status".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let maritalStatus = authService.user?.maritalStatus {
                                Text(maritalStatus.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .foregroundColor(.primary)
                            } else {
                                Text("profile.marital_status.not_set".localized)
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityHint("profile.marital_status.accessibility_hint".localized)

                        Spacer()

                        if isEditing {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(minHeight: 44)
                }
                .disabled(!isEditing)

                // Number of Children
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .foregroundColor(.green)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    if isEditing {
                        Stepper(value: $numberOfChildren, in: 0...20) {
                            HStack {
                                Text("profile.number_of_children".localized)
                                Spacer()
                                Text("\(numberOfChildren)")
                                    .foregroundColor(.primary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.number_of_children".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(authService.user?.numberOfChildren ?? 0)")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 44)
            } header: {
                Text("profile.tax_info".localized)
            }

            // Tax Year & Workspace
            Section {
                // Tax Year Selection
                if let workspace = workspaceManager.currentWorkspace {
                    Button(action: {
                        showYearPicker = true
                    }) {
                        HStack(alignment: .center, spacing: .paddingStandard) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                                Text("profile.tax_year".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(workspace.taxYear)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("profile.tax_year.accessibility_hint".localized)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(minHeight: 44)
                    }
                } else {
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))
                        Text("profile.workspace.not_found".localized)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)
                }

                // Workspace Information
                if let workspace = workspaceManager.currentWorkspace {
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "folder")
                            .foregroundColor(.purple)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.workspace_name".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(workspace.name)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)

                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "person.2")
                            .foregroundColor(.green)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                            Text("profile.workspace_type".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(workspace.type.rawValue.capitalized)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)
                }
            } header: {
                Text("profile.tax_year_workspace".localized)
            } footer: {
                Text("profile.tax_year_workspace.footer".localized)
            }

            // Person 1 & Person 2 (Joint Filing) - Only show if married or in registered partnership
            let isJointFiling = authService.user?.maritalStatus == .married || authService.user?.maritalStatus == .registered_partnership

            if isJointFiling {
                Section {
                    // Person 1
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        if isEditing {
                            VStack(alignment: .leading, spacing: .paddingStandard) {
                                TextField("profile.person1_name".localized, text: $person1Name)
                                    .profileTextField()

                                TextField("profile.person1_ahv".localized, text: $person1AhvNumber)
                                    .keyboardType(.numberPad)
                                    .profileTextField()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                                Text("profile.person1_name".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let person1Name = authService.user?.person1Name {
                                    Text(person1Name)
                                        .font(.body)

                                    if let person1Ahv = authService.user?.person1AhvNumber {
                                        Text("AHV: \(person1Ahv)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("profile.person1.not_set".localized)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(minHeight: 44)

                    // Person 2
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        if isEditing {
                            VStack(alignment: .leading, spacing: .paddingStandard) {
                                TextField("profile.person2_name".localized, text: $person2Name)
                                    .profileTextField()

                                TextField("profile.person2_ahv".localized, text: $person2AhvNumber)
                                    .keyboardType(.numberPad)
                                    .profileTextField()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                                Text("profile.person2_name".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let person2Name = authService.user?.person2Name {
                                    Text(person2Name)
                                        .font(.body)

                                    if let person2Ahv = authService.user?.person2AhvNumber {
                                        Text("AHV: \(person2Ahv)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("profile.person2.not_set".localized)
                                        .foregroundColor(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("profile.joint_filing".localized)
                } footer: {
                    Text("profile.joint_filing.footer".localized)
                }
            }

            // Account Status with Glass Background
            Section {
                HStack(alignment: .center, spacing: .paddingStandard) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.green)
                        .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                        .font(.system(size: 18))

                    Text("profile.account_status".localized)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("profile.status.active".localized)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .glassBackground(thickness: .thin, cornerRadius: 8, tintColor: .green)
                }
                .frame(minHeight: 44)

                if let createdAt = authService.user?.createdAt {
                    HStack(alignment: .center, spacing: .paddingStandard) {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.blue)
                            .frame(width: .iconSizeExtraLarge, height: .iconSizeExtraLarge)
                            .font(.system(size: 18))

                        Text("profile.member_since".localized)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Text(createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    .frame(minHeight: 44)
                }
            } header: {
                Text("profile.account_info".localized)
            }

            // Messages
            if !errorMessage.isEmpty {
                Section {
                    Label {
                        Text(errorMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            if !successMessage.isEmpty {
                Section {
                    Label {
                        Text(successMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .sheet(isPresented: $showCantonPicker) {
            NavigationView {
                List {
                    ForEach(cantonHelper.allCantons) { canton in
                        Button(action: {
                            Task {
                                await changeCanton(to: canton.id)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(canton.displayName)
                                        .foregroundColor(.primary)
                                    HStack {
                                        Text(canton.id)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if canton.hasOnlinePortal {
                                            Label("Online Portal", systemImage: "globe")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                Spacer()
                                if canton.id == authService.user?.canton {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.taxedPrimary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("profile.select_canton".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("profile.cancel".localized) {
                            showCantonPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showMaritalStatusPicker) {
            NavigationView {
                List {
                    ForEach([MaritalStatus.single, .married, .divorced, .widowed, .registered_partnership], id: \.self) { status in
                        Button(action: {
                            maritalStatus = status
                            showMaritalStatusPicker = false
                        }) {
                            HStack {
                                Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .foregroundColor(.primary)
                                Spacer()
                                if status == maritalStatus {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.taxedPrimary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("profile.select_marital_status".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("profile.cancel".localized) {
                            showMaritalStatusPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showYearPicker) {
            NavigationView {
                List {
                    ForEach(availableYears, id: \.self) { year in
                        Button(action: {
                            Task {
                                await changeTaxYear(to: year)
                            }
                        }) {
                            HStack {
                                Text(String(year))
                                    .foregroundColor(.primary)
                                Spacer()
                                if year == workspaceManager.currentWorkspace?.taxYear {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.taxedPrimary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("profile.select_tax_year".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("profile.cancel".localized) {
                            showYearPicker = false
                        }
                    }
                }
            }
        }
        .task {
            await loadWorkspace()
        }
        .onAppear {
            loadUserData()
        }
    }

    // MARK: - Helper Methods

    private func loadUserData() {
        if let user = authService.user {
            name = user.name
            email = user.email
            phone = user.phone ?? ""
            selectedCanton = user.canton
            municipality = user.municipality ?? ""
            municipalityId = user.municipalityId ?? ""

            // Address fields
            street = user.street ?? ""
            postalCode = user.postalCode ?? ""
            city = user.city ?? ""

            // Tax information
            maritalStatus = user.maritalStatus
            numberOfChildren = user.numberOfChildren ?? 0

            // Person 1 & Person 2 fields
            person1Name = user.person1Name ?? ""
            person1AhvNumber = user.person1AhvNumber ?? ""
            person2Name = user.person2Name ?? ""
            person2AhvNumber = user.person2AhvNumber ?? ""
        }
    }

    private func toggleEditMode() {
        if isEditing {
            Task {
                await saveProfile()
            }
        } else {
            isEditing = true
        }
    }

    private func saveProfile() async {
        guard let userId = authService.user?.id else {
            errorMessage = "profile.error.no_user".localized
            return
        }

        isSaving = true
        defer {
            isSaving = false
            isEditing = false
        }

        do {
            var data: [String: Any] = [
                "name": name,
                "updatedAt": Timestamp(date: Date())
            ]

            if !phone.isEmpty {
                data["phone"] = phone
            }

            if !municipality.isEmpty {
                data["municipality"] = municipality
            }

            if !municipalityId.isEmpty {
                data["municipalityId"] = municipalityId
            }

            // Address fields
            if !street.isEmpty {
                data["street"] = street
            }

            if !postalCode.isEmpty {
                data["postalCode"] = postalCode
            }

            if !city.isEmpty {
                data["city"] = city
            }

            // Tax information
            if let maritalStatus = maritalStatus {
                data["maritalStatus"] = maritalStatus.rawValue
            }

            data["numberOfChildren"] = numberOfChildren

            // Person 1 & Person 2 fields
            if !person1Name.isEmpty {
                data["person1Name"] = person1Name
            }

            if !person1AhvNumber.isEmpty {
                data["person1AhvNumber"] = person1AhvNumber
            }

            if !person2Name.isEmpty {
                data["person2Name"] = person2Name
            }

            if !person2AhvNumber.isEmpty {
                data["person2AhvNumber"] = person2AhvNumber
            }

            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.saved".localized

            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = ""
            }
        }
    }

    private func changeCanton(to cantonId: String) async {
        guard let userId = authService.user?.id else {
            errorMessage = "profile.error.no_user".localized
            return
        }

        do {
            let data: [String: Any] = [
                "canton": cantonId,
                "updatedAt": Timestamp(date: Date())
            ]
            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.canton.changed".localized(with: cantonHelper.getCantonDisplayName(forId: cantonId))
            showCantonPicker = false

            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = ""
            }
        }
    }

    private func loadWorkspace() async {
        guard let userId = authService.user?.id else {
            await MainActor.run {
                isLoadingWorkspace = false
                errorMessage = "profile.error.no_user".localized
            }
            return
        }

        await workspaceManager.loadCurrentWorkspace(userId: userId)
        await MainActor.run {
            isLoadingWorkspace = false

            if workspaceManager.currentWorkspace == nil {
                errorMessage = "profile.error.no_workspace_found".localized
            }
        }
    }

    private func changeTaxYear(to year: Int) async {
        guard let workspace = workspaceManager.currentWorkspace else {
            errorMessage = "profile.error.no_workspace".localized
            return
        }

        var updatedWorkspace = workspace
        updatedWorkspace.taxYear = year
        updatedWorkspace.updatedAt = Date()

        do {
            try await workspaceManager.updateWorkspace(updatedWorkspace)

            // CRITICAL: Reload documents with the new tax year filter
            await DocumentManager.shared.loadDocuments(forWorkspace: updatedWorkspace)

            successMessage = "profile.tax_year.changed".localized(with: String(year))
            showYearPicker = false

            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = ""
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthenticationService())
    }
}