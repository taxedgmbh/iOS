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

    /// Generate document-centric storage path: documents/{customerId}/{taxYear}/{category}/{subcategory}/{documentId}/{fileType}
    /// All related files (original.pdf, cover.pdf, complete.pdf) are grouped in the same documentId folder
    private func generateStoragePath(
        customerId: String,
        documentId: String,
        fileType: String, // e.g., "original.pdf", "cover.pdf", "complete.pdf"
        taxYear: Int,
        category: String,
        subcategory: String
    ) -> String {
        if !subcategory.isEmpty {
            return "documents/\(customerId)/\(taxYear)/\(category)/\(subcategory)/\(documentId)/\(fileType)"
        } else {
            return "documents/\(customerId)/\(taxYear)/\(category)/\(documentId)/\(fileType)"
        }
    }

    /// Legacy method for backwards compatibility with non-document-centric paths
    /// Used for old upload methods that don't use documentId folders
    @available(*, deprecated, message: "Use generateStoragePath with documentId instead")
    private func generateLegacyStoragePath(
        customerId: String,
        fileName: String,
        taxYear: Int? = nil,
        category: String? = nil,
        subcategory: String? = nil
    ) -> String {
        // If we have full organization info, use hierarchical structure
        if let year = taxYear, let cat = category {
            if let subcat = subcategory, !subcat.isEmpty {
                return "documents/\(customerId)/\(year)/\(cat)/\(subcat)/\(fileName)"
            } else {
                return "documents/\(customerId)/\(year)/\(cat)/\(fileName)"
            }
        }

        // Fallback to flat structure for backwards compatibility
        return "documents/\(customerId)/\(fileName)"
    }

    // MARK: - Upload Methods

    /// Upload a document image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - customerId: The customer's user ID
    ///   - fileName: Name of the file
    ///   - taxYear: Optional tax year for organization
    ///   - category: Optional category for organization
    ///   - subcategory: Optional subcategory for organization
    ///   - progressHandler: Optional progress callback (0.0 to 1.0)
    /// - Returns: The download URL as a string
    func uploadDocument(
        image: UIImage,
        customerId: String,
        fileName: String,
        taxYear: Int? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.imageConversionFailed
        }

        // Create organized storage path using legacy method
        let path = generateLegacyStoragePath(
            customerId: customerId,
            fileName: fileName,
            taxYear: taxYear,
            category: category,
            subcategory: subcategory
        )
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

        // Wait for upload using continuation to properly await completion
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { _ in
                    print("✅ Image uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
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

        // Get download URL with retry logic
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

        print("✅ Complete upload process finished: \(path)")
        return finalURL.absoluteString
    }

    /// Upload a document from Data (for PDFs, etc.)
    func uploadDocumentData(
        data: Data,
        customerId: String,
        fileName: String,
        mimeType: String,
        taxYear: Int? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        let path = generateLegacyStoragePath(
            customerId: customerId,
            fileName: fileName,
            taxYear: taxYear,
            category: category,
            subcategory: subcategory
        )
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

        // Wait for upload using continuation to properly await completion
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { _ in
                    print("✅ Data uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
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

        // Get download URL with retry logic
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

        print("✅ Complete upload process finished: \(path)")
        return finalURL.absoluteString
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
        customerId: String,
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

            return try await uploadPDFData(finalPDF, customerId: customerId, documentId: documentId, documentType: documentType, taxYear: taxYear, category: category, subcategory: subcategory, attachmentNumber: attachmentNumber, progressHandler: progressHandler)
        }

        // 5. Upload PDF with document-centric path structure
        let path = generateStoragePath(
            customerId: customerId,
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
            "uploadedBy": customerId,
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

        // Wait for upload using continuation to properly await completion
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { _ in
                    print("✅ PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
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
    ///   - customerId: The customer's user ID
    ///   - documentId: Existing document ID (from original upload)
    ///   - fileType: Type of file - "cover.pdf" or "complete.pdf"
    ///   - taxYear: Tax year for organization
    ///   - category: Category for organization
    ///   - subcategory: Subcategory for organization
    ///   - progressHandler: Optional progress callback
    /// - Returns: The download URL for the uploaded file
    func uploadRelatedPDF(
        pdfData: Data,
        customerId: String,
        documentId: String,
        fileType: String, // "cover.pdf" or "complete.pdf"
        taxYear: Int,
        category: String,
        subcategory: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        print("📎 Uploading related file: \(fileType) for documentId: \(documentId)")

        let path = generateStoragePath(
            customerId: customerId,
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
            "uploadedBy": customerId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "documentId": documentId,
            "fileType": fileType,
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

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { _ in
                    print("✅ Related PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
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
        customerId: String,
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
            customerId: customerId,
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
            "uploadedBy": customerId,
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

        // Wait for upload using continuation to properly await completion
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { _ in
                    print("✅ PDF uploaded successfully: \(path)")
                    continuation.resume(returning: ())
                }

                uploadTask.observe(.failure) { snapshot in
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
