//
//  UploadSheet.swift
//  TaxedGmbH_IOS
//
//  Sending a document.
//
//  The client picks a **category**, and that is all the server is told about
//  where the file should go. It resolves the folder id from the household's own
//  record. Sending a folder id from a device would let any session with a token
//  write anywhere in the company's Shared Drive — including other clients'
//  folders.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct UploadSheet: View {
    let householdId: String
    let categories: [PortalCategory]
    let service: PortalDocumentsService
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: PortalSession

    @State private var pickedFile: PickedFile?
    @State private var category: String = ""
    @State private var taxYear = AppConstants.Uploads.defaultTaxYear
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showFileImporter = false
    @State private var photoItem: PhotosPickerItem?

    /// `00_Permanent` is not year-bound — a residence permit or an AHV
    /// certificate belongs to the person, not to a filing period. Asking for a
    /// tax year there would be a question with no right answer.
    private var selectedIsPermanent: Bool {
        categories.first { $0.key == category }?.permanent == true
    }

    private var years: [Int] {
        let latest = AppConstants.Uploads.defaultTaxYear
        // Most recent first, and one year ahead of the default for the client
        // who is early — the server creates the year folder on demand.
        return Array(((latest - 5)...(latest + 1)).reversed())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("upload.file".localized) {
                    if let pickedFile {
                        LabeledContent(pickedFile.name) {
                            Text(Format.fileSize(pickedFile.size))
                                .foregroundStyle(.secondary)
                        }
                        Button("upload.choose_different".localized) { self.pickedFile = nil }
                            .frame(minHeight: 44)
                    } else {
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("upload.choose_file".localized, systemImage: "folder")
                                .frame(minHeight: 44)
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("upload.choose_photo".localized, systemImage: "photo")
                                .frame(minHeight: 44)
                        }
                    }
                }

                Section("upload.category".localized) {
                    Picker("upload.category".localized, selection: $category) {
                        ForEach(categories, id: \.key) { item in
                            Text(DriveCategory.label(for: item.key)).tag(item.key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                if !selectedIsPermanent {
                    Section("upload.tax_year".localized) {
                        Picker("upload.tax_year".localized, selection: $taxYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    Section {
                        Text("upload.tax_year.hint".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
            .navigationTitle("upload.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                        .disabled(isUploading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Button("upload.send".localized) { Task { await upload() } }
                            .disabled(pickedFile == nil || category.isEmpty)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .spreadsheet, .presentation, .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { adopt(url) }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .task(id: photoItem) { await adoptPhoto() }
            .onAppear {
                if category.isEmpty { category = categories.first?.key ?? "" }
            }
            .interactiveDismissDisabled(isUploading)
        }
    }

    // MARK: - Picking

    /// Copies the picked file into our own temporary directory.
    ///
    /// A document-picker URL is a security-scoped loan that can be revoked
    /// before the upload finishes; a file we own cannot vanish underneath us.
    private func adopt(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)

        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: url, to: destination)
            let size = Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            pickedFile = PickedFile(url: destination, name: url.lastPathComponent, size: size)
            errorMessage = nil
        } catch {
            errorMessage = "upload.error.unreadable".localized
        }
    }

    private func adoptPhoto() async {
        guard let photoItem else { return }
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self) else { return }
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("uploads", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            // Named after when it was taken, because "IMG_4821.jpg" tells the
            // person reading the Drive folder nothing at all.
            let name = "Photo_\(Date().formatted(.iso8601.year().month().day())).jpg"
            let destination = directory.appendingPathComponent(UUID().uuidString + "-" + name)
            try data.write(to: destination)
            pickedFile = PickedFile(url: destination, name: name, size: Int64(data.count))
            errorMessage = nil
        } catch {
            errorMessage = "upload.error.unreadable".localized
        }
        self.photoItem = nil
    }

    // MARK: - Sending

    private func upload() async {
        guard let pickedFile else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        do {
            try await service.upload(
                fileURL: pickedFile.url,
                fileName: pickedFile.name,
                category: category,
                taxYear: selectedIsPermanent ? nil : taxYear,
                householdId: householdId
            )
            try? FileManager.default.removeItem(at: pickedFile.url)
            onFinished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            session.noteAPIError(error)
        }
    }
}

private struct PickedFile {
    let url: URL
    let name: String
    let size: Int64
}
