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
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "more.notifications".localized,
                    subtitle: "more.notifications.subtitle".localized,
                    destination: AnyView(NotificationSettingsView())
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
                    icon: "lock.shield.fill",
                    iconColor: .red,
                    title: "more.security".localized,
                    subtitle: "more.security.subtitle".localized,
                    destination: AnyView(SecuritySettingsView())
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
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var profileImageURL: String?
    @State private var isUploadingImage = false
    @State private var showSaveAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var exportedDataURL: URL?
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

                if let canton = authService.user?.canton {
                    ProfileInfoRow(
                        label: "settings.profile.canton".localized,
                        value: canton,
                        icon: "mappin.circle.fill",
                        isEditable: false
                    )
                }
            } header: {
                Text("profile.personal_info".localized)
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
        .sheet(item: $exportedDataURL) { url in
            ActivityViewController(activityItems: [url])
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
        let totalFields = 5

        if let user = authService.user {
            if !user.name.isEmpty { completeness += 1 }
            if !user.email.isEmpty { completeness += 1 }
            if !(user.phone ?? "").isEmpty { completeness += 1 }
            if user.canton != nil { completeness += 1 }
            if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty { completeness += 1 }
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
                    exportedDataURL = fileURL
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

// MARK: - URL Extension for Identifiable
// Note: This is needed for sheet(item:) with URL
// If Foundation adds this conformance in the future, remove this extension
extension URL: Identifiable {
    public var id: String { absoluteString }
}

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

// MARK: - About View

struct AboutView: View {
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    Image("taxed-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .padding()

                    VStack(spacing: 8) {
                        Text("Taxed GmbH")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("more.about.tagline".localized)
                            .font(.subheadline)
                            .foregroundColor(.taxedPrimary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))

                VStack(spacing: 24) {
                    // Company Overview
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.about.header".localized)

                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "more.about.bullet1".localized)
                            BulletPoint(text: "more.about.bullet2".localized)
                            BulletPoint(text: "more.about.bullet3".localized)
                            BulletPoint(text: "more.about.bullet4".localized)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Company Details
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.company_details.header".localized)

                        CompanyDetailRow(label: "more.company_details.name".localized, value: "Taxed GmbH")
                        CompanyDetailRow(label: "more.company_details.address".localized, value: "Aegertenstrasse 10, 2503 Biel/Bienne")
                        CompanyDetailRow(label: "more.company_details.country".localized, value: "Switzerland 🇨🇭")
                        CompanyDetailRow(label: "more.company_details.phone".localized, value: "+41 79 910 77 87")
                        CompanyDetailRow(label: "more.company_details.email".localized, value: "info@taxed.ch")
                        CompanyDetailRow(label: "more.company_details.website".localized, value: "www.taxed.ch")
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Business Information
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.business_info.header".localized)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("more.business_info.uid".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("more.business_info.zefix_entry".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Link("more.business_info.zefix_link".localized, destination: URL(string: "https://www.zefix.ch")!)
                                    .font(.caption)
                                    .foregroundColor(.taxedPrimary)

                                Text("more.business_info.zefix_subtitle".localized)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Services
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.services.header".localized)

                        ServiceCard(
                            icon: "doc.text",
                            title: "more.services.tax_returns.title".localized,
                            description: "more.services.tax_returns.description".localized
                        )

                        ServiceCard(
                            icon: "person.2.fill",
                            title: "more.services.expat_advice.title".localized,
                            description: "more.services.expat_advice.description".localized
                        )

                        ServiceCard(
                            icon: "checkmark.circle",
                            title: "more.services.ai_processing.title".localized,
                            description: "more.services.ai_processing.description".localized
                        )

                        ServiceCard(
                            icon: "lock.shield",
                            title: "more.services.data_protection.title".localized,
                            description: "more.services.data_protection.description".localized
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Trust & Certifications
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.trust.header".localized)

                        TrustBadge(icon: "checkmark.seal.fill", title: "more.trust.gdpr.title".localized, subtitle: "more.trust.gdpr.subtitle".localized)
                        TrustBadge(icon: "lock.fill", title: "more.trust.encryption.title".localized, subtitle: "more.trust.encryption.subtitle".localized)
                        TrustBadge(icon: "person.badge.shield.checkmark", title: "more.trust.experts.title".localized, subtitle: "more.trust.experts.subtitle".localized)
                        TrustBadge(icon: "firebaselogo.fill", title: "more.trust.cloud.title".localized, subtitle: "more.trust.cloud.subtitle".localized)
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Version & Legal
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "more.app_info.header".localized)

                        CompanyDetailRow(label: "more.app_info.version".localized, value: "1.0.0")
                        CompanyDetailRow(label: "Build", value: "2025.001")
                        CompanyDetailRow(label: "Platform", value: "iOS 26.0+")

                        HStack {
                            Text("more.app_info.privacy".localized)
                                .font(.body)
                            Spacer()
                            Link("more.app_info.read".localized, destination: URL(string: "https://taxed.ch/datenschutz")!)
                                .font(.body)
                                .foregroundColor(.taxedPrimary)
                        }

                        HStack {
                            Text("more.app_info.terms".localized)
                                .font(.body)
                            Spacer()
                            Link("more.app_info.read".localized, destination: URL(string: "https://taxed.ch/impressum")!)
                                .font(.body)
                                .foregroundColor(.taxedPrimary)
                        }
                    }
                    .padding(.horizontal)

                    // Footer
                    VStack(spacing: 8) {
                        Text("© 2025 Taxed GmbH. Alle Rechte vorbehalten.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link(destination: URL(string: "https://taxed.ch")!) {
                                Label("Website", systemImage: "globe")
                                    .font(.caption)
                            }

                            Link(destination: URL(string: "https://www.linkedin.com/company/taxed-gmbh")!) {
                                Label("LinkedIn", systemImage: "link")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.taxedPrimary)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Über Taxed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.taxedPrimary)
                .frame(width: 4, height: 20)
        }
    }
}

struct CompanyDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .fontWeight(.medium)

            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.taxedPrimary)
                .padding(.top, 6)

            Text(text)
                .font(.body)
                .lineLimit(nil)

            Spacer()
        }
    }
}

struct ServiceCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.taxedPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.taxedPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TrustBadge: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Privacy View - PRODUCTION READY

struct PrivacyView: View {
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("privacy.last_updated".localized)
                    .font(.caption)
                    .foregroundColor(.gray)

                Group {
                    privacySection(
                        title: "privacy.intro.title".localized,
                        content: "privacy.intro.content".localized
                    )

                    privacySection(
                        title: "privacy.data_collection.title".localized,
                        content: "privacy.data_collection.content".localized
                    )

                    privacySection(
                        title: "privacy.data_use.title".localized,
                        content: "privacy.data_use.content".localized
                    )

                    privacySection(
                        title: "privacy.data_protection.title".localized,
                        content: "privacy.data_protection.content".localized
                    )

                    privacySection(
                        title: "privacy.your_rights.title".localized,
                        content: "privacy.your_rights.content".localized
                    )

                    privacySection(
                        title: "privacy.contact.title".localized,
                        content: "privacy.contact.content".localized
                    )
                }
            }
            .padding()
        }
        .navigationTitle("more.privacy".localized)
    }

    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Terms View - PRODUCTION READY

struct TermsView: View {
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("terms.last_updated".localized)
                    .font(.caption)
                    .foregroundColor(.gray)

                Group {
                    termsSection(
                        title: "terms.acceptance.title".localized,
                        content: "terms.acceptance.content".localized
                    )

                    termsSection(
                        title: "terms.services.title".localized,
                        content: "terms.services.content".localized
                    )

                    termsSection(
                        title: "terms.user_obligations.title".localized,
                        content: "terms.user_obligations.content".localized
                    )

                    termsSection(
                        title: "terms.fees.title".localized,
                        content: "terms.fees.content".localized
                    )

                    termsSection(
                        title: "terms.liability.title".localized,
                        content: "terms.liability.content".localized
                    )

                    termsSection(
                        title: "terms.termination.title".localized,
                        content: "terms.termination.content".localized
                    )

                    termsSection(
                        title: "terms.governing_law.title".localized,
                        content: "terms.governing_law.content".localized
                    )
                }
            }
            .padding()
        }
        .navigationTitle("more.terms".localized)
    }

    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Accessibility Settings View

struct AccessibilitySettingsView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var voiceOverEnabled = false
    @State private var largerText = false
    @State private var reduceMotion = false
    @State private var increaseContrast = false

    var body: some View {
        Form {
            Section(header: Text("accessibility.vision.header".localized),
                    footer: Text("accessibility.vision.footer".localized)) {
                Toggle("accessibility.larger_text".localized, isOn: $largerText)
                Toggle("accessibility.increase_contrast".localized, isOn: $increaseContrast)
            }

            Section(header: Text("accessibility.motion.header".localized),
                    footer: Text("accessibility.motion.footer".localized)) {
                Toggle("accessibility.reduce_motion".localized, isOn: $reduceMotion)
            }

            Section(header: Text("accessibility.voiceover.header".localized),
                    footer: Text("accessibility.voiceover.footer".localized)) {
                Toggle("accessibility.voiceover".localized, isOn: $voiceOverEnabled)
            }

            Section {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    HStack {
                        Text("accessibility.system_settings".localized)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("more.accessibility".localized)
    }
}

// MARK: - Security Settings View

struct SecuritySettingsView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var biometricEnabled = false
    @State private var requirePassword = true
    @State private var autoLockEnabled = true
    @State private var autoLockTime = 5

    var body: some View {
        Form {
            Section(header: Text("security.authentication.header".localized),
                    footer: Text("security.authentication.footer".localized)) {
                Toggle("security.biometric_auth".localized, isOn: $biometricEnabled)
                Toggle("security.require_password".localized, isOn: $requirePassword)
            }

            Section(header: Text("security.auto_lock.header".localized),
                    footer: Text("security.auto_lock.footer".localized)) {
                Toggle("security.auto_lock_enabled".localized, isOn: $autoLockEnabled)

                if autoLockEnabled {
                    Picker("security.auto_lock_time".localized, selection: $autoLockTime) {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }
                }
            }

            Section(header: Text("security.data.header".localized)) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("security.encryption.title".localized)
                            .font(.subheadline)
                        Text("security.encryption.description".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("more.security".localized)
    }
}

// MARK: - Report Issue View

struct ReportIssueView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var issueType = "bug"
    @State private var issueTitle = ""
    @State private var issueDescription = ""
    @State private var includeDeviceInfo = true
    @State private var showMailComposer = false
    @State private var showMailErrorAlert = false
    @State private var mailComposeResult: Result<MFMailComposeResult, Error>?

    var body: some View {
        Form {
            Section(header: Text("report.type.header".localized)) {
                Picker("report.type".localized, selection: $issueType) {
                    Text("report.type.bug".localized).tag("bug")
                    Text("report.type.feature".localized).tag("feature")
                    Text("report.type.improvement".localized).tag("improvement")
                    Text("report.type.other".localized).tag("other")
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("report.details.header".localized)) {
                TextField("report.title".localized, text: $issueTitle)

                ZStack(alignment: .topLeading) {
                    if issueDescription.isEmpty {
                        Text("report.description.placeholder".localized)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $issueDescription)
                        .frame(minHeight: 100)
                }
            }

            Section(header: Text("report.additional.header".localized)) {
                Toggle("report.include_device_info".localized, isOn: $includeDeviceInfo)

                if includeDeviceInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("report.device_info".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("iOS \(UIDevice.current.systemVersion)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(UIDevice.current.model)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button(action: submitIssue) {
                    HStack {
                        Spacer()
                        Text("report.submit".localized)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(issueTitle.isEmpty || issueDescription.isEmpty)
            }
        }
        .navigationTitle("more.report_issue".localized)
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipients: ["support@taxed.ch"],
                subject: getEmailSubject(),
                body: getEmailBody(),
                onDismiss: { result in
                    mailComposeResult = result
                    switch result {
                    case .success(let mailResult):
                        if mailResult == .sent {
                            presentationMode.wrappedValue.dismiss()
                        }
                    case .failure:
                        showMailErrorAlert = true
                    }
                }
            )
        }
        .alert("report.error.title".localized, isPresented: $showMailErrorAlert) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text("report.error.message".localized)
        }
    }

    private func submitIssue() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailErrorAlert = true
        }
    }

    private func getEmailSubject() -> String {
        let typeString = "report.type.\(issueType)".localized
        return "[\(typeString)] \(issueTitle)"
    }

    private func getEmailBody() -> String {
        var body = """
        Issue Type: \("report.type.\(issueType)".localized)
        Title: \(issueTitle)

        Description:
        \(issueDescription)

        """

        if includeDeviceInfo {
            body += """

            ---
            Device Information:
            - iOS Version: \(UIDevice.current.systemVersion)
            - Device Model: \(UIDevice.current.model)
            - App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            - Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            """
        }

        return body
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let onDismiss: (Result<MFMailComposeResult, Error>) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: (Result<MFMailComposeResult, Error>) -> Void

        init(onDismiss: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error = error {
                onDismiss(.failure(error))
            } else {
                onDismiss(.success(result))
            }
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        MoreView()
            .environmentObject(AuthenticationService())
    }
}
