//
//  CameraPicker.swift
//  TaxedGmbH_IOS
//
//  UIKit wrapper for capturing images with camera
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        // CRITICAL: Set source type BEFORE any other camera-specific settings
        // Check if camera is available (not available in simulator)
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

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let capturedImage = info[.originalImage] as? UIImage {
                parent.image = capturedImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    // CameraPicker is a UIViewControllerRepresentable, preview shows placeholder
    Text("CameraPicker Preview")
        .font(.headline)
        .foregroundColor(.secondary)
}
