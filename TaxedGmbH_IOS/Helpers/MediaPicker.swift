//
//  MediaPicker.swift
//  TaxedGmbH_IOS
//
//  Unified picker for camera, photo library, and documents with multi-select support
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI

// MARK: - Source Type

enum MediaPickerSourceType {
    case camera
    case photoLibrary
    case files
}

// MARK: - Media Picker (Camera & Photo Library)

struct MediaPicker: UIViewControllerRepresentable {
    let sourceType: MediaPickerSourceType
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss

    // Single image convenience initializer
    init(sourceType: MediaPickerSourceType, image: Binding<UIImage?>) {
        self.sourceType = sourceType
        self._images = Binding(
            get: { image.wrappedValue.map { [$0] } ?? [] },
            set: { image.wrappedValue = $0.first }
        )
    }

    // Multiple images initializer
    init(sourceType: MediaPickerSourceType, images: Binding<[UIImage]>) {
        self.sourceType = sourceType
        self._images = images
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        // Configure based on source type
        switch sourceType {
        case .camera:
            #if targetEnvironment(simulator)
            // Force photo library in simulator to prevent crashes
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            #else
            // On real devices, try camera first, fall back to photo library
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                picker.cameraCaptureMode = .photo
            } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            #endif

        case .photoLibrary:
            picker.sourceType = .photoLibrary

        case .files:
            // This case shouldn't be used with UIImagePickerController
            // Use DocumentPicker instead
            break
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MediaPicker

        init(_ parent: MediaPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.images = [selectedImage]
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker (Files with Multi-Select)

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [SelectedFile]
    let allowsMultipleSelection: Bool
    @Environment(\.dismiss) private var dismiss

    // Single file convenience initializer (backwards compatible)
    init(documentURL: Binding<URL?>) {
        self._selectedFiles = Binding(
            get: { documentURL.wrappedValue.map { [SelectedFile(url: $0, image: nil)] } ?? [] },
            set: { documentURL.wrappedValue = $0.first?.url }
        )
        self.allowsMultipleSelection = false
    }

    // Multiple files initializer
    init(selectedFiles: Binding<[SelectedFile]>, allowsMultipleSelection: Bool = true) {
        self._selectedFiles = selectedFiles
        self.allowsMultipleSelection = allowsMultipleSelection
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .pdf,
                .image,
                .jpeg,
                .png,
                .heic,
                .text,
                .plainText
            ],
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var selectedFiles: [SelectedFile] = []

            for url in urls {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("❌ Could not access security-scoped resource: \(url.lastPathComponent)")
                    continue
                }

                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                // Copy file to temporary directory
                let fileName = url.lastPathComponent
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)

                do {
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    // Copy the file
                    try FileManager.default.copyItem(at: url, to: tempURL)

                    // Try to load as image if it's an image file
                    var image: UIImage?
                    if let data = try? Data(contentsOf: tempURL),
                       let loadedImage = UIImage(data: data) {
                        image = loadedImage
                    }

                    selectedFiles.append(SelectedFile(url: tempURL, image: image))
                    print("✅ Document copied to: \(tempURL.path)")
                } catch {
                    print("❌ Error copying document: \(error)")
                }
            }

            parent.selectedFiles = selectedFiles
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.selectedFiles = []
        }
    }
}

// MARK: - Selected File Model

struct SelectedFile: Identifiable {
    let id = UUID()
    let url: URL
    let image: UIImage?

    var fileName: String {
        url.lastPathComponent
    }

    var fileExtension: String {
        url.pathExtension.uppercased()
    }

    var isImage: Bool {
        image != nil
    }
}

// MARK: - Photo Library Picker (SwiftUI Native - Multi-Select)

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let selectionLimit: Int
    @Environment(\.dismiss) private var dismiss

    init(images: Binding<[UIImage]>, selectionLimit: Int = 0) {
        self._images = images
        self.selectionLimit = selectionLimit
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit // 0 = unlimited

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard !results.isEmpty else { return }

            var loadedImages: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }

                    if let error = error {
                        print("❌ Error loading image: \(error)")
                        return
                    }

                    if let image = object as? UIImage {
                        loadedImages.append(image)
                    }
                }
            }

            group.notify(queue: .main) {
                self.parent.images = loadedImages
                print("✅ Loaded \(loadedImages.count) images from photo library")
            }
        }
    }
}
