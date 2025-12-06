//
//  DocumentScannerPicker.swift
//  TaxedGmbH_IOS
//
//  Professional document scanner using Apple's VNDocumentCameraViewController
//  Perfect for scanning A4 tax documents with automatic edge detection and perspective correction
//

import SwiftUI
import VisionKit
import UIKit

struct DocumentScannerPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerPicker

        init(_ parent: DocumentScannerPicker) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            print("📄 Document scan completed successfully")
            print("   - Number of pages: \(scan.pageCount)")

            // Get the first scanned page (most common use case for tax documents)
            if scan.pageCount > 0 {
                let scannedImage = scan.imageOfPage(at: 0)
                parent.image = scannedImage

                print("✅ Document scanned:")
                print("   - Size: \(scannedImage.size.width) x \(scannedImage.size.height)")
                print("   - Scale: \(scannedImage.scale)")
            } else {
                print("⚠️ No pages scanned")
            }

            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("❌ Document scan cancelled by user")
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("❌ Document scan failed: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}

#Preview {
    // DocumentScannerPicker is a UIViewControllerRepresentable, preview shows placeholder
    Text("Document Scanner")
        .font(.headline)
        .foregroundColor(.secondary)
}
