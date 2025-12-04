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

    // MARK: - Path Generation

    /// Generate workspace-centric storage path: workspaces/{workspaceId}/{taxYear}/{documentId}/{fileType}
    /// All related files (original.pdf, cover_sheet.pdf, processed.pdf) are grouped in the same documentId folder
    /// Categories and subcategories are stored in Firestore metadata, not in storage paths (for agility)
    /// Workspaces enable collaborative access - multiple users (e.g., spouses) can share document access
    private func generateStoragePath(
        workspaceId: String,  // Changed from customerId to workspaceId for collaboration
        documentId: String,
        fileType: String, // e.g., "original.pdf", "cover_sheet.pdf", "processed.pdf"
        taxYear: Int,
        category: String, // Kept for signature compatibility, but not used in path
        subcategory: String // Kept for signature compatibility, but not used in path
    ) -> String {
        return "workspaces/\(workspaceId)/\(taxYear)/\(documentId)/\(fileType)"
    }

    // MARK: - Upload Methods

    /// Delete a document from Firebase Storage
    func deleteDocument(storageUrl: String) async throws {
        guard !storageUrl.isEmpty else {
            print("❌ Empty storage URL for deletion")
            throw StorageError.invalidURL
        }

        // Determine if it's a full URL or a storage path
        let storageRef: StorageReference
        if let url = URL(string: storageUrl),
           let scheme = url.scheme,
           ["gs", "http", "https"].contains(scheme) {
            // Full URL with scheme
            storageRef = storage.reference(forURL: storageUrl)
        } else {
            // Storage path
            storageRef = storage.reference().child(storageUrl)
        }

        try await storageRef.delete()
        print("✅ Document deleted: \(storageUrl)")
    }

    /// Get file size from storage URL
    func getFileSize(storageUrl: String) async throws -> Int64 {
        guard !storageUrl.isEmpty else {
            print("❌ Empty storage URL for getFileSize")
            throw StorageError.invalidURL
        }

        // Determine if it's a full URL or a storage path
        let storageRef: StorageReference
        if let url = URL(string: storageUrl),
           let scheme = url.scheme,
           ["gs", "http", "https"].contains(scheme) {
            // Full URL with scheme
            storageRef = storage.reference(forURL: storageUrl)
        } else {
            // Storage path
            storageRef = storage.reference().child(storageUrl)
        }

        let metadata = try await storageRef.getMetadata()
        return metadata.size
    }

    // MARK: - Optimized Upload with PDF Conversion

    /// Upload document as optimized PDF in A4 format using document-centric storage
    /// - Parameters:
    ///   - image: The UIImage to convert and upload
    ///   - customerId: The customer's user ID
    ///   - documentType: Type of document (e.g., "lohnausweis", "spesenbeleg")
    ///   - taxYear: Tax year for organization (required)
    ///   - category: Category for organization (required)
    ///   - subcategory: Subcategory for organization (required)
    ///   - attachmentNumber: Optional attachment number for file labeling (e.g., "SAL_1234")
    ///   - progressHandler: Optional progress callback (0.0 to 1.0)
    /// - Returns: Tuple of (downloadURL, documentId) - documentId is needed for related files (cover, complete)
    func uploadDocumentAsPDF(
        image: UIImage,
        workspaceId: String,
        documentType: String,
        taxYear: Int,
        category: String,
        subcategory: String,
        attachmentNumber: String? = nil,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> (downloadURL: String, documentId: String) {
        // 1. Generate documentId early - needed for storage path
        let documentId = UUID().uuidString
        print("🆔 Generated document ID: \(documentId)")

        // 2. Compress and resize image for optimal quality/size balance
        print("📸 Original image size: \(image.size)")
        guard let compressedImage = compressImage(image, maxWidth: 1240, maxHeight: 1754, quality: 0.5) else {
            throw StorageError.compressionFailed
        }
        print("✅ Compressed image size: \(compressedImage.size)")

        // 3. Convert to PDF in A4 format with additional compression
        guard let pdfData = convertImageToPDFA4(compressedImage, quality: 0.5) else {
            throw StorageError.pdfGenerationFailed
        }

        let pdfSizeKB = Double(pdfData.count) / 1024.0
        let pdfSizeMB = Double(pdfData.count) / (1024.0 * 1024.0)
        print("📄 PDF size: \(String(format: "%.2f", pdfSizeKB)) KB (\(String(format: "%.2f", pdfSizeMB)) MB)")

        // 4. Validate file size (max 4 MB as required)
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

            return try await uploadPDFData(finalPDF, workspaceId: workspaceId, documentId: documentId, documentType: documentType, taxYear: taxYear, category: category, subcategory: subcategory, attachmentNumber: attachmentNumber, progressHandler: progressHandler)
        }

        // 5. Upload PDF with document-centric path structure
        let path = generateStoragePath(
            workspaceId: workspaceId,
            documentId: documentId,
            fileType: "original.pdf",
            taxYear: taxYear,
            category: category,
            subcategory: subcategory
        )
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "workspaceId": workspaceId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentType": documentType,
            "documentId": documentId,
            "attachmentNumber": attachmentNumber ?? "",
            "format": "A4",
            "fileType": "original"
        ]

        isUploading = true
        uploadProgress = 0.0

        // Use async/await upload with progress tracking
        let uploadTask = storageRef.putData(pdfData, metadata: metadata)

        // Observe progress in background
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload completion with guard to prevent double-resume
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var hasResumed = false

                uploadTask.observe(.success) { _ in
                    guard !hasResumed else {
                        print("⚠️ Success observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    print("✅ PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
                    guard !hasResumed else {
                        print("⚠️ Failure observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    if let error = snapshot.error {
                        print("❌ Upload failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.uploadFailed
        }

        // Get download URL with retry logic (sometimes takes a moment for Firebase to propagate)
        var downloadURL: URL?
        var lastError: Error?

        for attempt in 1...3 {
            do {
                downloadURL = try await storageRef.downloadURL()
                print("✅ Download URL retrieved (attempt \(attempt)): \(downloadURL?.absoluteString ?? "nil")")
                break
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt)/3 to get download URL failed: \(error.localizedDescription)")
                if attempt < 3 {
                    // Wait a bit before retrying
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            }
        }

        guard let finalURL = downloadURL else {
            print("❌ Failed to get download URL after 3 attempts: \(lastError?.localizedDescription ?? "unknown error")")
            print("   Note: File was uploaded successfully but download URL retrieval failed")
            print("   Path: \(path)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.invalidURL
        }

        isUploading = false
        uploadProgress = 0.0

        print("✅ Complete upload process finished: \(path)")
        print("🆔 Returning documentId: \(documentId)")
        return (downloadURL: finalURL.absoluteString, documentId: documentId)
    }

    // MARK: - Related File Upload

    /// Upload related PDF files (cover sheet, complete document) using existing documentId
    /// - Parameters:
    ///   - pdfData: The PDF data to upload
    ///   - workspaceId: The workspace ID
    ///   - documentId: Existing document ID (from original upload)
    ///   - fileType: Type of file - "cover.pdf" or "complete.pdf"
    ///   - taxYear: Tax year for organization
    ///   - category: Category for organization
    ///   - subcategory: Subcategory for organization
    ///   - progressHandler: Optional progress callback
    /// - Returns: The download URL for the uploaded file
    func uploadRelatedPDF(
        pdfData: Data,
        workspaceId: String,
        documentId: String,
        fileType: String, // "cover.pdf" or "complete.pdf"
        taxYear: Int,
        category: String,
        subcategory: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        print("📎 Uploading related file: \(fileType) for documentId: \(documentId)")

        let path = generateStoragePath(
            workspaceId: workspaceId,
            documentId: documentId,
            fileType: fileType,
            taxYear: taxYear,
            category: category,
            subcategory: subcategory
        )
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "workspaceId": workspaceId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentId": documentId,
            "fileType": fileType,
            "format": "A4"
        ]

        isUploading = true
        uploadProgress = 0.0

        let uploadTask = storageRef.putData(pdfData, metadata: metadata)

        uploadTask.observe(StorageTaskStatus.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var hasResumed = false

                uploadTask.observe(StorageTaskStatus.success) { _ in
                    guard !hasResumed else {
                        print("⚠️ Success observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    print("✅ Related PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(StorageTaskStatus.failure) { snapshot in
                    guard !hasResumed else {
                        print("⚠️ Failure observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    if let error = snapshot.error {
                        print("❌ Upload failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.uploadFailed
        }

        var downloadURL: URL?
        var lastError: Error?

        for attempt in 1...3 {
            do {
                downloadURL = try await storageRef.downloadURL()
                print("✅ Download URL retrieved (attempt \(attempt)): \(downloadURL?.absoluteString ?? "nil")")
                break
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt)/3 to get download URL failed: \(error.localizedDescription)")
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }

        guard let finalURL = downloadURL else {
            print("❌ Failed to get download URL after 3 attempts: \(lastError?.localizedDescription ?? "unknown error")")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.invalidURL
        }

        isUploading = false
        uploadProgress = 0.0

        print("✅ Related file upload complete: \(path)")
        return finalURL.absoluteString
    }

    // MARK: - Helper Methods

    /// Helper to upload PDF data with document-centric storage
    private func uploadPDFData(
        _ pdfData: Data,
        workspaceId: String,
        documentId: String,
        documentType: String,
        taxYear: Int,
        category: String,
        subcategory: String,
        attachmentNumber: String? = nil,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (downloadURL: String, documentId: String) {
        print("🆔 Using provided document ID: \(documentId)")

        let path = generateStoragePath(
            workspaceId: workspaceId,
            documentId: documentId,
            fileType: "original.pdf",
            taxYear: taxYear,
            category: category,
            subcategory: subcategory
        )
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "workspaceId": workspaceId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentType": documentType,
            "documentId": documentId,
            "attachmentNumber": attachmentNumber ?? "",
            "format": "A4",
            "fileType": "original"
        ]

        isUploading = true
        uploadProgress = 0.0

        // Use async/await upload with progress tracking
        let uploadTask = storageRef.putData(pdfData, metadata: metadata)

        // Observe progress in background
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            Task { @MainActor in
                self.uploadProgress = percentComplete
                progressHandler?(percentComplete)
            }
        }

        // Wait for upload completion with guard to prevent double-resume
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var hasResumed = false

                uploadTask.observe(.success) { _ in
                    guard !hasResumed else {
                        print("⚠️ Success observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    print("✅ PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
                    guard !hasResumed else {
                        print("⚠️ Failure observer called but continuation already resumed")
                        return
                    }
                    hasResumed = true
                    if let error = snapshot.error {
                        print("❌ Upload failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.uploadFailed
        }

        // Get download URL with retry logic (sometimes takes a moment for Firebase to propagate)
        var downloadURL: URL?
        var lastError: Error?

        for attempt in 1...3 {
            do {
                downloadURL = try await storageRef.downloadURL()
                print("✅ Download URL retrieved (attempt \(attempt)): \(downloadURL?.absoluteString ?? "nil")")
                break
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt)/3 to get download URL failed: \(error.localizedDescription)")
                if attempt < 3 {
                    // Wait a bit before retrying
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            }
        }

        guard let finalURL = downloadURL else {
            print("❌ Failed to get download URL after 3 attempts: \(lastError?.localizedDescription ?? "unknown error")")
            print("   Note: File was uploaded successfully but download URL retrieval failed")
            print("   Path: \(path)")
            isUploading = false
            uploadProgress = 0.0
            throw StorageError.invalidURL
        }

        isUploading = false
        uploadProgress = 0.0

        print("✅ Complete upload process finished: \(path)")
        print("🆔 Returning documentId: \(documentId)")
        return (downloadURL: finalURL.absoluteString, documentId: documentId)
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
