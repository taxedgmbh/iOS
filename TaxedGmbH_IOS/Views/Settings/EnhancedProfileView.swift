//
//  EnhancedProfileView.swift
//  TaxedGmbH_IOS
//
//  Comprehensive profile management with joint filing support and spouse invitation
//

import SwiftUI
import FirebaseFirestore

struct EnhancedProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared

    // Personal Information
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    // Address
    @State private var street: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""

    // Tax Information
    @State private var selectedCanton: String?
    @State private var municipality: String = ""
    @State private var municipalityId: String = ""
    @State private var maritalStatus: MaritalStatus = .single
    @State private var numberOfChildren: Int = 0

    // Person 1 (Primary Taxpayer)
    @State private var person1Name: String = ""
    @State private var person1AhvNumber: String = ""

    // Person 2 (Spouse/Partner for Joint Filing)
    @State private var person2Name: String = ""
    @State private var person2AhvNumber: String = ""
    @State private var person2Email: String = ""

    // UI State
    @State private var showCantonPicker = false
    @State private var showMaritalStatusPicker = false
    @State private var showSpouseInvitation = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showChildrenPicker = false

    private let cantonHelper = SwissCantonHelper.shared

    var isJointFiling: Bool {
        maritalStatus == .married || maritalStatus == .registered_partnership
    }

    var body: some View {
        Form {
            // MARK: - Profile Header
            profileHeaderSection

            // MARK: - Personal Information
            personalInformationSection

            // MARK: - Address Section
            addressSection

            // MARK: - Tax Information
            taxInformationSection

            // MARK: - Joint Filing Section (only shown for married/partnership)
            if isJointFiling {
                jointFilingSection
            }

            // MARK: - Account Status
            accountStatusSection

            // MARK: - Messages
            messagesSection
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
            cantonPickerSheet
        }
        .sheet(isPresented: $showMaritalStatusPicker) {
            maritalStatusPickerSheet
        }
        .sheet(isPresented: $showSpouseInvitation) {
            spouseInvitationSheet
        }
        .sheet(isPresented: $showChildrenPicker) {
            childrenPickerSheet
        }
        .onAppear {
            loadUserData()
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        Section {
            GlassCard(thickness: .regular, tintColor: .blue) {
                HStack(spacing: .paddingRelaxed) {
                    // Profile Avatar
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

                        // Joint filing indicator
                        if isJointFiling {
                            Label("profile.joint_filing".localized, systemImage: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(.horizontal, .paddingTight)
                                .padding(.vertical, .paddingExtraTight)
                                .glassBackground(thickness: .thin, cornerRadius: .cornerRadiusMedium, tintColor: .purple)
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
    }

    // MARK: - Personal Information Section

    private var personalInformationSection: some View {
        Section {
            // Name Field
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .frame(width: 32)

                if isEditing {
                    TextField("profile.name".localized, text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.name".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(authService.user?.name ?? "")
                            .font(.body)
                    }
                }
            }

            // Email Field (read-only)
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.orange)
                    .frame(width: 32)

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
            }

            // Phone Field
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                    .frame(width: 32)

                if isEditing {
                    TextField("profile.phone".localized, text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.phone".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(authService.user?.phone?.isEmpty == false ? authService.user!.phone! : "profile.phone.not_set".localized)
                            .font(.body)
                            .foregroundColor(authService.user?.phone?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }
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
    }

    // MARK: - Address Section

    private var addressSection: some View {
        Section {
            // Street
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.cyan)
                    .frame(width: 32)

                if isEditing {
                    TextField("profile.street".localized, text: $street)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.street".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(authService.user?.street?.isEmpty == false ? authService.user!.street! : "profile.not_set".localized)
                            .font(.body)
                            .foregroundColor(authService.user?.street?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }

            // Postal Code & City
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.indigo)
                    .frame(width: 32)

                if isEditing {
                    VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
                        TextField("profile.postal_code".localized, text: $postalCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)

                        TextField("profile.city".localized, text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.location".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let postalCode = authService.user?.postalCode,
                           let city = authService.user?.city {
                            Text("\(postalCode) \(city)")
                                .font(.body)
                        } else {
                            Text("profile.not_set".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("profile.address".localized)
        } footer: {
            Text("profile.address.footer".localized)
        }
    }

    // MARK: - Tax Information Section

    private var taxInformationSection: some View {
        Section {
            // Canton
            Button(action: {
                showCantonPicker = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.canton".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            if let canton = authService.user?.canton {
                                Text(cantonHelper.getCantonDisplayName(forId: canton))
                                    .foregroundColor(.primary)
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
                    .accessibilityHint("profile.canton.accessibility_hint".localized)
                }
            }
            .accessibilityElement(children: .combine)

            // Municipality
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.purple)
                    .frame(width: 32)

                if isEditing {
                    VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
                        TextField("profile.municipality".localized, text: $municipality)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)

                        TextField("profile.municipality_id".localized, text: $municipalityId)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
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
                }
            }

            // Marital Status
            Button(action: {
                showMaritalStatusPicker = true
            }) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(.pink)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.marital_status".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(maritalStatus.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityHint("profile.marital_status.accessibility_hint".localized)
                }
            }
            .accessibilityElement(children: .combine)

            // Number of Children
            Button(action: {
                showChildrenPicker = true
            }) {
                HStack {
                    Image(systemName: "figure.and.child.holdinghands")
                        .foregroundColor(.mint)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.children".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(numberOfChildren)")
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Primary Taxpayer AHV
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.teal)
                    .frame(width: 32)

                if isEditing {
                    VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
                        TextField("profile.person1_ahv".localized, text: $person1AhvNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.ahv_number".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(authService.user?.person1AhvNumber?.isEmpty == false ? authService.user!.person1AhvNumber! : "profile.not_set".localized)
                            .font(.body)
                            .foregroundColor(authService.user?.person1AhvNumber?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }
        } header: {
            Text("profile.tax_info".localized)
        } footer: {
            Text("profile.tax_info.footer".localized)
        }
    }

    // MARK: - Joint Filing Section

    private var jointFilingSection: some View {
        Section {
            GlassCard(thickness: .thin, tintColor: .purple) {
                VStack(alignment: .leading, spacing: .paddingStandard) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                            .foregroundColor(.purple)

                        Text("profile.joint_filing.title".localized)
                            .font(.headline)

                        Spacer()
                    }

                    Text("profile.joint_filing.description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.paddingRelaxed)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: .paddingTight, leading: .paddingRelaxed, bottom: .paddingTight, trailing: .paddingRelaxed))

            // Spouse/Partner Name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.purple)
                    .frame(width: 32)

                if isEditing {
                    TextField("profile.person2_name".localized, text: $person2Name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } else{
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.spouse_name".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(authService.user?.person2Name?.isEmpty == false ? authService.user!.person2Name! : "profile.not_set".localized)
                            .font(.body)
                            .foregroundColor(authService.user?.person2Name?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }

            // Spouse/Partner AHV
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.purple)
                    .frame(width: 32)

                if isEditing {
                    TextField("profile.person2_ahv".localized, text: $person2AhvNumber)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                        Text("profile.spouse_ahv".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(authService.user?.person2AhvNumber?.isEmpty == false ? authService.user!.person2AhvNumber! : "profile.not_set".localized)
                            .font(.body)
                            .foregroundColor(authService.user?.person2AhvNumber?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }

            // Invite Spouse Button
            if authService.user?.person2Name?.isEmpty ?? true {
                Button(action: {
                    showSpouseInvitation = true
                }) {
                    GlassCard(thickness: .thin, tintColor: .blue) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(.blue)

                            Text("profile.invite_spouse".localized)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .foregroundColor(.blue)
                        }
                        .padding(.paddingRelaxed)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: .paddingTight, leading: .paddingRelaxed, bottom: .paddingTight, trailing: .paddingRelaxed))
            }
        } header: {
            Text("profile.joint_filing_section".localized)
        } footer: {
            Text("profile.joint_filing.footer".localized)
        }
    }

    // MARK: - Account Status Section

    private var accountStatusSection: some View {
        Section {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundColor(.green)
                    .frame(width: 32)

                Text("profile.account_status".localized)
                Spacer()
                Text("profile.status.active".localized)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .glassBackground(thickness: .thin, cornerRadius: 8, tintColor: .green)
            }

            if let createdAt = authService.user?.createdAt {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    Text("profile.member_since".localized)
                    Spacer()
                    Text(createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("profile.account_info".localized)
        }
    }

    // MARK: - Messages Section

    private var messagesSection: some View {
        Group {
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
    }

    // MARK: - Picker Sheets

    private var cantonPickerSheet: some View {
        NavigationView {
            List {
                ForEach(cantonHelper.allCantons) { canton in
                    Button(action: {
                        Task {
                            await changeCanton(to: canton.id)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: .verticalSpacingTight) {
                                Text(canton.displayName)
                                    .foregroundColor(.primary)
                                HStack {
                                    Text(canton.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if canton.hasOnlinePortal {
                                        Label("profile.canton.online_portal".localized, systemImage: "globe")
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

    private var maritalStatusPickerSheet: some View {
        NavigationView {
            List {
                ForEach([MaritalStatus.single, .married, .registered_partnership, .divorced, .widowed], id: \.self) { status in
                    Button(action: {
                        maritalStatus = status
                        showMaritalStatusPicker = false
                        Task {
                            await saveMaritalStatus()
                        }
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

    private var childrenPickerSheet: some View {
        NavigationView {
            List {
                ForEach(0..<11, id: \.self) { count in
                    Button(action: {
                        numberOfChildren = count
                        showChildrenPicker = false
                        Task {
                            await saveNumberOfChildren()
                        }
                    }) {
                        HStack {
                            Text("\(count)")
                                .foregroundColor(.primary)
                            Spacer()
                            if count == numberOfChildren {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.taxedPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("profile.select_children".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("profile.cancel".localized) {
                        showChildrenPicker = false
                    }
                }
            }
        }
    }

    private var spouseInvitationSheet: some View {
        NavigationView {
            Form {
                Section {
                    GlassCard(thickness: .regular, tintColor: .purple) {
                        VStack(alignment: .leading, spacing: .paddingStandard) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.title)
                                    .foregroundColor(.purple)

                                VStack(alignment: .leading) {
                                    Text("profile.invite_spouse.title".localized)
                                        .font(.headline)
                                    Text("profile.invite_spouse.subtitle".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.paddingRelaxed)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: .paddingTight, leading: .paddingRelaxed, bottom: .paddingTight, trailing: .paddingRelaxed))
                }

                Section {
                    TextField("profile.spouse_email".localized, text: $person2Email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                } header: {
                    Text("profile.spouse_email.header".localized)
                } footer: {
                    Text("profile.spouse_email.footer".localized)
                }

                Section {
                    Button(action: sendSpouseInvitation) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("profile.send_invitation".localized)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(person2Email.isEmpty || isSaving)
                }
            }
            .navigationTitle("profile.invite_spouse".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("profile.cancel".localized) {
                        showSpouseInvitation = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadUserData() {
        if let user = authService.user {
            name = user.name
            email = user.email
            phone = user.phone ?? ""
            street = user.street ?? ""
            postalCode = user.postalCode ?? ""
            city = user.city ?? ""
            selectedCanton = user.canton
            municipality = user.municipality ?? ""
            municipalityId = user.municipalityId ?? ""
            maritalStatus = user.maritalStatus ?? .single
            numberOfChildren = user.numberOfChildren ?? 0
            person1Name = user.person1Name ?? user.name
            person1AhvNumber = user.person1AhvNumber ?? user.ahvNumber ?? ""
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
                "updatedAt": Timestamp(date: Date()),
                "profileLastUpdatedAt": Timestamp(date: Date()),
                "profileVersion": (authService.user?.profileVersion ?? 1) + 1
            ]

            if !phone.isEmpty { data["phone"] = phone }
            if !street.isEmpty { data["street"] = street }
            if !postalCode.isEmpty { data["postalCode"] = postalCode }
            if !city.isEmpty { data["city"] = city }
            if !municipality.isEmpty { data["municipality"] = municipality }
            if !municipalityId.isEmpty { data["municipalityId"] = municipalityId }
            if !person1Name.isEmpty { data["person1Name"] = person1Name }
            if !person1AhvNumber.isEmpty { data["person1AhvNumber"] = person1AhvNumber }
            if !person2Name.isEmpty { data["person2Name"] = person2Name }
            if !person2AhvNumber.isEmpty { data["person2AhvNumber"] = person2AhvNumber }

            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.saved".localized

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
                "updatedAt": Timestamp(date: Date()),
                "profileLastUpdatedAt": Timestamp(date: Date()),
                "profileVersion": (authService.user?.profileVersion ?? 1) + 1
            ]
            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.canton.changed".localized
            showCantonPicker = false

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

    private func saveMaritalStatus() async {
        guard let userId = authService.user?.id else { return }

        do {
            let data: [String: Any] = [
                "maritalStatus": maritalStatus.rawValue,
                "updatedAt": Timestamp(date: Date()),
                "profileLastUpdatedAt": Timestamp(date: Date()),
                "profileVersion": (authService.user?.profileVersion ?? 1) + 1
            ]
            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.marital_status.updated".localized

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveNumberOfChildren() async {
        guard let userId = authService.user?.id else { return }

        do {
            let data: [String: Any] = [
                "numberOfChildren": numberOfChildren,
                "updatedAt": Timestamp(date: Date()),
                "profileLastUpdatedAt": Timestamp(date: Date()),
                "profileVersion": (authService.user?.profileVersion ?? 1) + 1
            ]
            try await authService.updateUser(userId: userId, data: data)
            successMessage = "profile.children.updated".localized

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendSpouseInvitation() {
        // TODO: Implement email invitation via Firebase Cloud Functions
        // This would:
        // 1. Generate a unique invitation token
        // 2. Send email to spouse with invitation link
        // 3. Link accounts when spouse accepts

        isSaving = true

        // Simulate sending invitation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaving = false
            successMessage = "profile.invitation.sent".localized
            showSpouseInvitation = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        }
    }
}

#Preview {
    NavigationView {
        EnhancedProfileView()
            .environmentObject(AuthenticationService())
    }
}
