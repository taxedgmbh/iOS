//
//  PDFViewerRepresentable.swift
//  TaxedGmbH_IOS
//
//  Professional PDF viewer using PDFKit
//

import SwiftUI
import PDFKit
import FirebaseStorage

struct PDFViewerRepresentable: UIViewRepresentable {
    let url: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only load if:
        // 1. URL has changed from what's currently loaded
        // 2. We're not already in the process of loading
        guard context.coordinator.loadedURL != url else {
            return  // Already loaded this URL
        }
        guard !context.coordinator.isLoading else {
            return  // Currently loading, don't start another
        }

        print("🔄 Loading PDF for URL change")
        context.coordinator.loadPDF(url: url, into: pdfView, isLoading: $isLoading)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var loadedURL: String?  // Track the URL that's successfully loaded
        var isLoading: Bool = false
        private var loadTask: Task<Void, Never>?

        func loadPDF(url: String, into pdfView: PDFView, isLoading: Binding<Bool>) {
            // Cancel any existing load task
            loadTask?.cancel()

            // Mark as loading immediately
            self.isLoading = true

            loadTask = Task {
                await MainActor.run {
                    isLoading.wrappedValue = true
                }

                do {
                    let storageRef = Storage.storage().reference(forURL: url)
                    let maxSize: Int64 = 50 * 1024 * 1024 // 50MB
                    let data = try await storageRef.data(maxSize: maxSize)

                    guard !Task.isCancelled else {
                        print("⏸️ PDF load cancelled for: \(url)")
                        return
                    }

                    if let pdfDocument = PDFDocument(data: data) {
                        await MainActor.run {
                            pdfView.document = pdfDocument
                            isLoading.wrappedValue = false
                        }
                        // Mark as successfully loaded
                        self.loadedURL = url
                        self.isLoading = false
                        print("✅ PDF loaded successfully")
                    } else {
                        print("❌ Failed to create PDFDocument from data")
                        await MainActor.run {
                            // Create error placeholder PDF
                            pdfView.document = createErrorPlaceholderPDF(message: "Invalid PDF format")
                            isLoading.wrappedValue = false
                        }
                        // Still mark as "loaded" to prevent retry loop
                        self.loadedURL = url
                        self.isLoading = false
                    }
                } catch {
                    guard !Task.isCancelled else {
                        self.isLoading = false
                        return
                    }

                    let errorMessage: String
                    if let storageError = error as NSError?, storageError.code == 404 {
                        errorMessage = "Document not found in storage"
                        print("❌ Error loading PDF (404): File not found - \(url)")
                    } else {
                        errorMessage = "Failed to load document"
                        print("❌ Error loading PDF: \(error.localizedDescription)")
                    }

                    await MainActor.run {
                        // Show error message instead of infinite loading
                        pdfView.document = createErrorPlaceholderPDF(message: errorMessage)
                        isLoading.wrappedValue = false
                    }
                    // Mark as "loaded" (with error) to prevent retry loop
                    self.loadedURL = url
                    self.isLoading = false
                }
            }
        }

        private func createErrorPlaceholderPDF(message: String) -> PDFDocument? {
            // Create a simple error message PDF
            let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
            let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

            let data = renderer.pdfData { context in
                context.beginPage()

                // Draw error icon and message
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.systemRed,
                    .paragraphStyle: paragraphStyle
                ]

                let messageAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraphStyle
                ]

                "⚠️".draw(in: CGRect(x: 0, y: 250, width: pageSize.width, height: 60), withAttributes: titleAttributes)
                message.draw(in: CGRect(x: 50, y: 350, width: pageSize.width - 100, height: 100), withAttributes: messageAttributes)
            }

            return PDFDocument(data: data)
        }

        deinit {
            loadTask?.cancel()
        }
    }
}

// Thumbnail generator for list view
struct PDFThumbnailGenerator {
    static func generateThumbnail(from url: String, size: CGSize = CGSize(width: 140, height: 140)) async -> UIImage? {
        do {
            let storageRef = Storage.storage().reference(forURL: url)
            let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
            let data = try await storageRef.data(maxSize: maxSize)

            guard let pdfDocument = PDFDocument(data: data),
                  let page = pdfDocument.page(at: 0) else {
                return nil
            }

            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: size)

            let thumbnail = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: 1, y: -1)

                let scaleX = size.width / pageRect.width
                let scaleY = size.height / pageRect.height
                let scale = min(scaleX, scaleY)

                context.cgContext.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: context.cgContext)
            }

            return thumbnail
        } catch {
            print("❌ Error generating PDF thumbnail: \(error)")
            return nil
        }
    }
}
