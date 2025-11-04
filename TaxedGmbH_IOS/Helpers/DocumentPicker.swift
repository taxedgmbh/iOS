//
//  DocumentPicker.swift
//  TaxedGmbH_IOS
//
//  SwiftUI wrapper for UIDocumentPickerViewController
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var documentURL: URL?
    @Environment(\.dismiss) private var dismiss

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
        picker.allowsMultipleSelection = false
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
            guard let url = urls.first else { return }

            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Could not access security-scoped resource")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Copy file to temporary directory
            let fileName = url.lastPathComponent
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }

                // Copy the file
                try FileManager.default.copyItem(at: url, to: tempURL)

                parent.documentURL = tempURL
                print("✅ Document copied to: \(tempURL.path)")
            } catch {
                print("❌ Error copying document: \(error)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.documentURL = nil
        }
    }
}
