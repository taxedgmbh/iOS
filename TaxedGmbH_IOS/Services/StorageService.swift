//
//  StorageService.swift
//  TaxedGmbH_IOS
//
//  Handles Firebase Storage uploads for tax documents
//

import Foundation
import FirebaseStorage
import UIKit
import Combine
import PDFKit

enum StorageError: Error {
    case imageConversionFailed
    case uploadFailed
    case invalidURL
    case unauthorized
    case pdfGenerationFailed
    case compressionFailed
}

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()

    private let storage = Storage.storage()
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false

    private init() {}

    /// Upload a document image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - customerId: The customer's user ID
    ///   - fileName: Name of the file
    ///   - progressHandler: Optional progress callback (0.0 to 1.0)
    /// - Returns: The download URL as a string
    func uploadDocument(
        image: UIImage,
        customerId: String,
        fileName: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.imageConversionFailed
        }

        // Create storage path: documents/{customerId}/{fileName}
        let path = "documents/\(customerId)/\(fileName)"
        let storageRef = storage.reference().child(path)

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedBy": customerId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Upload with progress tracking
        isUploading = true
        uploadProgress = 0.0

        let uploadTask = storageRef.putData(imageData, metadata: metadata)

        // Observe upload progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload to complete and get metadata
        _ = uploadTask

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()

        isUploading = false
        uploadProgress = 0.0

        print("✅ Document uploaded successfully: \(path)")
        return downloadURL.absoluteString
    }

    /// Upload a document from Data (for PDFs, etc.)
    func uploadDocumentData(
        data: Data,
        customerId: String,
        fileName: String,
        mimeType: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        let path = "documents/\(customerId)/\(fileName)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = mimeType
        metadata.customMetadata = [
            "uploadedBy": customerId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        isUploading = true
        uploadProgress = 0.0

        let uploadTask = storageRef.putData(data, metadata: metadata)

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload to complete and get metadata
        _ = uploadTask
        let downloadURL = try await storageRef.downloadURL()

        isUploading = false
        uploadProgress = 0.0

        print("✅ Document data uploaded successfully: \(path)")
        return downloadURL.absoluteString
    }

    /// Delete a document from Firebase Storage
    func deleteDocument(storageUrl: String) async throws {
        let storageRef = storage.reference(forURL: storageUrl)
        try await storageRef.delete()
        print("✅ Document deleted: \(storageUrl)")
    }

    /// Get file size from storage URL
    func getFileSize(storageUrl: String) async throws -> Int64 {
        let storageRef = storage.reference(forURL: storageUrl)
        let metadata = try await storageRef.getMetadata()
        return metadata.size
    }

    // MARK: - Optimized Upload with PDF Conversion

    /// Upload document as optimized PDF in A4 format with UUID-based naming
    /// - Parameters:
    ///   - image: The UIImage to convert and upload
    ///   - customerId: The customer's user ID
    ///   - documentType: Type of document (e.g., "lohnausweis", "spesenbeleg")
    ///   - progressHandler: Optional progress callback (0.0 to 1.0)
    /// - Returns: The download URL as a string
    func uploadDocumentAsPDF(
        image: UIImage,
        customerId: String,
        documentType: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        // 1. Compress and resize image for optimal quality/size balance
        print("📸 Original image size: \(image.size)")
        guard let compressedImage = compressImage(image, maxWidth: 1240, maxHeight: 1754, quality: 0.5) else {
            throw StorageError.compressionFailed
        }
        print("✅ Compressed image size: \(compressedImage.size)")

        // 2. Convert to PDF in A4 format with additional compression
        guard let pdfData = convertImageToPDFA4(compressedImage, quality: 0.5) else {
            throw StorageError.pdfGenerationFailed
        }

        let pdfSizeKB = Double(pdfData.count) / 1024.0
        let pdfSizeMB = Double(pdfData.count) / (1024.0 * 1024.0)
        print("📄 PDF size: \(String(format: "%.2f", pdfSizeKB)) KB (\(String(format: "%.2f", pdfSizeMB)) MB)")

        // 3. Validate file size (max 4 MB as required)
        let maxSizeBytes = 4 * 1024 * 1024  // 4 MB limit
        if pdfData.count > maxSizeBytes {
            print("⚠️ PDF too large (\(String(format: "%.2f", pdfSizeMB)) MB), applying aggressive compression...")

            // Try progressively more aggressive compression until we get under 4MB
            var compressedPDF: Data?
            let attempts = [
                (maxWidth: 1000, maxHeight: 1415, quality: 0.4),
                (maxWidth: 800, maxHeight: 1132, quality: 0.3),
                (maxWidth: 600, maxHeight: 849, quality: 0.25),
                (maxWidth: 500, maxHeight: 707, quality: 0.2)
            ]

            for (index, attempt) in attempts.enumerated() {
                print("   Attempt \(index + 1): \(attempt.maxWidth)x\(attempt.maxHeight) @ \(Int(attempt.quality * 100))% quality")
                guard let recompressedImage = compressImage(image, maxWidth: CGFloat(attempt.maxWidth), maxHeight: CGFloat(attempt.maxHeight), quality: attempt.quality) else {
                    continue
                }
                guard let attemptPDF = convertImageToPDFA4(recompressedImage, quality: attempt.quality) else {
                    continue
                }

                let attemptSizeMB = Double(attemptPDF.count) / (1024.0 * 1024.0)
                print("   Result: \(String(format: "%.2f", attemptSizeMB)) MB")

                if attemptPDF.count <= maxSizeBytes {
                    compressedPDF = attemptPDF
                    print("✅ Successfully compressed to \(String(format: "%.2f", attemptSizeMB)) MB")
                    break
                }
            }

            guard let finalPDF = compressedPDF else {
                print("❌ Failed to compress PDF below 4MB after all attempts")
                throw StorageError.compressionFailed
            }

            return try await uploadPDFData(finalPDF, customerId: customerId, documentType: documentType, progressHandler: progressHandler)
        }

        // 3. Generate UUID-based filename: {UUID}_{documentType}.pdf
        let documentId = UUID().uuidString
        let fileName = "\(documentId)_\(documentType).pdf"

        // 4. Upload PDF
        let path = "documents/\(customerId)/\(fileName)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "uploadedBy": customerId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentType": documentType,
            "documentId": documentId,
            "format": "A4"
        ]

        isUploading = true
        uploadProgress = 0.0

        let uploadTask = storageRef.putData(pdfData, metadata: metadata)

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload to complete
        _ = uploadTask
        print("✅ PDF data uploaded to Firebase Storage")

        // Get download URL
        let downloadURL: URL
        do {
            downloadURL = try await storageRef.downloadURL()
            print("✅ Download URL retrieved: \(downloadURL.absoluteString)")
        } catch {
            print("❌ Failed to get download URL: \(error.localizedDescription)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.invalidURL
        }

        isUploading = false
        uploadProgress = 0.0

        print("✅ PDF uploaded successfully: \(path)")
        return downloadURL.absoluteString
    }

    // MARK: - Helper Methods

    /// Helper to upload PDF data
    private func uploadPDFData(
        _ pdfData: Data,
        customerId: String,
        documentType: String,
        progressHandler: ((Double) -> Void)?
    ) async throws -> String {
        let documentId = UUID().uuidString
        let fileName = "\(documentId)_\(documentType).pdf"
        let path = "documents/\(customerId)/\(fileName)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "uploadedBy": customerId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentType": documentType,
            "documentId": documentId,
            "format": "A4"
        ]

        isUploading = true
        uploadProgress = 0.0

        let uploadTask = storageRef.putData(pdfData, metadata: metadata)

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload to complete
        _ = uploadTask
        print("✅ PDF data uploaded to Firebase Storage")

        // Get download URL
        let downloadURL: URL
        do {
            downloadURL = try await storageRef.downloadURL()
            print("✅ Download URL retrieved: \(downloadURL.absoluteString)")
        } catch {
            print("❌ Failed to get download URL: \(error.localizedDescription)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.invalidURL
        }

        isUploading = false
        uploadProgress = 0.0

        print("✅ PDF uploaded successfully: \(path)")
        return downloadURL.absoluteString
    }

    // MARK: - Image Processing Helpers

    /// Compress and resize image to fit within specified dimensions
    /// A4 paper at 200 DPI: 1654 x 2339 pixels (optimal for document scanning)
    private func compressImage(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat, quality: CGFloat = 0.7) -> UIImage? {
        let size = image.size

        // Calculate new size maintaining aspect ratio
        var newSize = size
        if size.width > maxWidth || size.height > maxHeight {
            let widthRatio = maxWidth / size.width
            let heightRatio = maxHeight / size.height
            let ratio = min(widthRatio, heightRatio)
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }

        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }

    /// Convert UIImage to PDF in A4 format with JPEG compression
    /// A4 dimensions: 595.2 x 841.8 points (8.27 x 11.69 inches at 72 DPI)
    private func convertImageToPDFA4(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        let pdfData = NSMutableData()

        // A4 size in points (72 DPI standard)
        let a4Size = CGSize(width: 595.2, height: 841.8)
        var mediaBox = CGRect(origin: .zero, size: a4Size)

        // Create PDF context
        guard let pdfConsumer = CGDataConsumer(data: pdfData),
              let pdfContext = CGContext(consumer: pdfConsumer,
                                        mediaBox: &mediaBox,
                                        nil) else {
            return nil
        }

        // Begin PDF page
        pdfContext.beginPage(mediaBox: &mediaBox)

        // Calculate image size to fit within A4 while maintaining aspect ratio
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height
        let a4Aspect = a4Size.width / a4Size.height

        var drawRect = CGRect.zero
        if imageAspect > a4Aspect {
            // Image is wider - fit to width
            drawRect.size.width = a4Size.width
            drawRect.size.height = a4Size.width / imageAspect
            drawRect.origin.x = 0
            drawRect.origin.y = (a4Size.height - drawRect.size.height) / 2
        } else {
            // Image is taller - fit to height
            drawRect.size.height = a4Size.height
            drawRect.size.width = a4Size.height * imageAspect
            drawRect.origin.x = (a4Size.width - drawRect.size.width) / 2
            drawRect.origin.y = 0
        }

        // Compress image to JPEG before adding to PDF
        if let compressedJPEGData = image.jpegData(compressionQuality: quality),
           let compressedImage = UIImage(data: compressedJPEGData),
           let cgImage = compressedImage.cgImage {
            pdfContext.draw(cgImage, in: drawRect)
        } else if let cgImage = image.cgImage {
            // Fallback to original if compression fails
            pdfContext.draw(cgImage, in: drawRect)
        }

        // End PDF page
        pdfContext.endPage()
        pdfContext.closePDF()

        return pdfData as Data
    }
}
