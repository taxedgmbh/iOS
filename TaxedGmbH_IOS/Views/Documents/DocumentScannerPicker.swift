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

            guard scan.pageCount > 0 else {
                print("⚠️ No pages scanned")
                parent.dismiss()
                return
            }

            if scan.pageCount == 1 {
                // Single page - use directly
                let scannedImage = scan.imageOfPage(at: 0)
                parent.image = scannedImage
                print("✅ Single page scanned: \(scannedImage.size.width) x \(scannedImage.size.height)")
            } else {
                // Multiple pages - combine into single vertical image
                print("📄 Combining \(scan.pageCount) pages into single image...")
                let combinedImage = combinePages(from: scan)
                parent.image = combinedImage
                print("✅ Combined \(scan.pageCount) pages: \(combinedImage?.size.width ?? 0) x \(combinedImage?.size.height ?? 0)")
            }

            parent.dismiss()
        }

        /// Combine multiple scanned pages into a single vertical image
        private func combinePages(from scan: VNDocumentCameraScan) -> UIImage? {
            var images: [UIImage] = []

            // Collect all scanned pages
            for pageIndex in 0..<scan.pageCount {
                let pageImage = scan.imageOfPage(at: pageIndex)
                images.append(pageImage)
            }

            guard !images.isEmpty else { return nil }

            // Calculate total height and max width
            let maxWidth = images.map { $0.size.width }.max() ?? 0
            let totalHeight = images.map { $0.size.height }.reduce(0, +)
            let spacing: CGFloat = 20 // Space between pages
            let finalHeight = totalHeight + (CGFloat(images.count - 1) * spacing)

            // Create combined image
            let format = UIGraphicsImageRendererFormat()
            format.scale = images[0].scale

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxWidth, height: finalHeight), format: format)

            let combinedImage = renderer.image { context in
                var yOffset: CGFloat = 0

                for image in images {
                    // Center image horizontally if it's narrower than maxWidth
                    let xOffset = (maxWidth - image.size.width) / 2
                    image.draw(at: CGPoint(x: xOffset, y: yOffset))
                    yOffset += image.size.height + spacing
                }
            }

            return combinedImage
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
