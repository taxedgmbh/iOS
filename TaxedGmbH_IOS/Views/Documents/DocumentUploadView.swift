//
//  DocumentUploadView.swift
//  TaxedGmbH_IOS
//
//  Main view for uploading tax documents with camera or photo library
//

import SwiftUI

struct DocumentUploadView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var storageService = StorageService.shared
    @StateObject private var firestoreService = FirestoreService.shared
    @StateObject private var documentProcessor = DocumentProcessorService.shared

    @State private var selectedImage: UIImage?
    @State private var selectedDocumentURL: URL?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var uploadProgress: Double = 0.0
    @State private var isUploading = false
    @State private var uploadedDocumentId: String?
    @State private var uploadSuccess = false
    @State private var errorMessage: String?
    @State private var warningMessage: String?

    // Voice note states
    @State private var documentNotes: String = ""
    @State private var showingVoiceInput = false

    // AI Processing results
    @State private var aiCategory: TaxDocumentCategory?
    @State private var aiConfidence: Double?
    @State private var extractedText: String?
    @State private var aiProcessingFailed = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("documents.upload.title".localized)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("documents.upload.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    // Image Preview
                    if let image = selectedImage {
                        VStack(spacing: 12) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 4)

                            Button(action: {
                                selectedImage = nil
                                uploadSuccess = false
                                errorMessage = nil
                            }) {
                                Label("documents.upload.change_photo".localized, systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                    } else {
                        // Image Selection Buttons
                        VStack(spacing: 16) {
                            Button(action: { showCamera = true }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    Text("documents.upload.camera".localized)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(action: { showImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .font(.title3)
                                    Text("documents.upload.gallery".localized)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }

                            Button(action: { showDocumentPicker = true }) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .font(.title3)
                                    Text("documents.upload.files".localized)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // AI Processing Progress
                    if documentProcessor.isProcessing {
                        VStack(spacing: 12) {
                            ProgressView(value: documentProcessor.processingProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text("documents.ai.analyzing".localized(with: Int(documentProcessor.processingProgress * 100)))
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("documents.ai.processing".localized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // AI Categorization Result
                    if let category = aiCategory, let confidence = aiConfidence {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
                                Text("documents.ai.recognition".localized)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            }

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("documents.ai.document_type".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(category.displayName)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("documents.ai.accuracy".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(confidence * 100))%")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(confidence > 0.7 ? .green : .orange)
                                }
                            }

                            if confidence < 0.7 {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                    Text("documents.ai.low_accuracy".localized)
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Voice Note Section
                    if selectedImage != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                Text("Add Voice Note")
                                    .font(.headline)
                                Spacer()
                                CompactVoiceInputButton(text: $documentNotes)
                            }

                            if !documentNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Note:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(documentNotes)
                                        .font(.subheadline)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)

                                    Button(action: { documentNotes = "" }) {
                                        Text("Clear Note")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            } else {
                                Text("Record a voice note about this document")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Upload Progress
                    if isUploading {
                        VStack(spacing: 12) {
                            ProgressView(value: uploadProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text("documents.upload.uploading".localized(with: Int(uploadProgress * 100)))
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("documents.upload.saving".localized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Success Message
                    if uploadSuccess {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)

                            Text("documents.upload.success".localized)
                                .font(.headline)
                                .foregroundColor(.green)

                            Text("documents.upload.success_desc".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                                .font(.subheadline)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Warning Message
                    if let warning = warningMessage {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text(warning)
                                .font(.subheadline)
                        }
                        .foregroundColor(Color(red: 0.85, green: 0.1, blue: 0.1))
                        .padding()
                        .background(Color(red: 0.85, green: 0.1, blue: 0.1).opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Upload Button
                    if selectedImage != nil && !isUploading && !uploadSuccess {
                        Button(action: {
                            Task {
                                await uploadDocument()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title3)
                                Text("documents.upload.button".localized)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Done Button
                    if uploadSuccess {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("documents.upload.done".localized)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("documents.upload.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $selectedImage)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(documentURL: $selectedDocumentURL)
            }
            .onChange(of: selectedDocumentURL) { _, newURL in
                if let url = newURL {
                    handleDocumentSelection(url: url)
                }
            }
        }
    }

    // MARK: - Document Selection Handler

    private func handleDocumentSelection(url: URL) {
        // Try to load as image first
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            selectedImage = image
            print("✅ Loaded document as image: \(url.lastPathComponent)")
        } else {
            // For PDFs and other files, we'll handle them differently
            // For now, show an info message
            print("📄 Selected file: \(url.lastPathComponent)")
            // The file URL is already stored, we'll upload it directly
        }
    }

    // MARK: - Upload Logic

    private func uploadDocument() async {
        guard var image = selectedImage,
              let userId = authService.user?.id else {
            errorMessage = "documents.upload.error.not_logged_in".localized
            return
        }

        errorMessage = nil
        warningMessage = nil
        uploadSuccess = false

        do {
            // 0. Compress image to below 4MB BEFORE processing
            print("🗜️ Compressing image to below 4MB...")
            image = compressImageBelow4MB(image: image)
            print("✅ Image compressed successfully")

            // 1. Run AI processing on device (Vision OCR + Categorization)
            var processingResult: DocumentProcessingResult?

            do {
                print("🤖 Starting AI document processing...")
                processingResult = try await documentProcessor.processDocument(image: image)

                // Store AI results
                aiCategory = processingResult?.suggestedCategory
                aiConfidence = processingResult?.confidence
                extractedText = processingResult?.extractedText

                print("✅ AI Processing complete:")
                print("   Category: \(processingResult?.suggestedCategory.displayName ?? "unknown")")
                print("   Confidence: \(Int((processingResult?.confidence ?? 0) * 100))%")
                print("   Text length: \(processingResult?.extractedText.count ?? 0) chars")
                if let keywords = processingResult?.detectedKeywords {
                    print("   Keywords: \(keywords.joined(separator: ", "))")
                }
            } catch {
                // AI processing failed, but we'll continue with upload
                print("⚠️ AI processing failed: \(error.localizedDescription)")
                print("📤 Continuing with manual review upload...")
                aiProcessingFailed = true
                processingResult = nil

                // Set warning message (not error - upload continues)
                warningMessage = error.localizedDescription
            }

            // 2. Upload to Firebase Storage as optimized PDF
            isUploading = true

            // Use document type from AI categorization, or "uncategorized" if AI failed
            let documentType = processingResult?.suggestedCategory.rawValue ?? "uncategorized"

            // Map to TaxCategoryType for accurate subcategory tracking
            let taxCategoryType = mapToTaxCategoryType(processingResult?.suggestedCategory)

            // Get current tax year
            let taxYear = Calendar.current.component(.year, from: Date())

            // Prepare category info for organized storage
            let categoryRawValue = processingResult?.suggestedCategory.taxCategory.rawValue ?? "uncategorized"

            let downloadURL = try await storageService.uploadDocumentAsPDF(
                image: image,
                customerId: userId,
                documentType: documentType,
                taxYear: taxYear,
                category: categoryRawValue,
                subcategory: taxCategoryType
            ) { progress in
                uploadProgress = progress
            }

            // 3. Create Firestore document record with AI categorization (if available)
            // Extract document name from URL (UUID_documentType.pdf)
            let urlComponents = downloadURL.components(separatedBy: "/")
            let documentName = urlComponents.last?.removingPercentEncoding ?? "document.pdf"

            let document = TaxDocument(
                customerId: userId,
                name: documentName,
                storageUrl: downloadURL,
                category: processingResult?.suggestedCategory.taxCategory ?? .uncategorized,
                subcategory: processingResult?.suggestedCategory.rawValue,
                aiConfidence: processingResult?.confidence,
                extractedText: processingResult?.extractedText,
                aiSummary: processingResult != nil ? generateDocumentSummary(result: processingResult!) : "documents.upload.manual_review_required".localized,
                status: {
                    if let result = processingResult {
                        return result.confidence > 0.7 ? .pending : .processing
                    } else {
                        // No AI result - needs manual processing
                        return .processing
                    }
                }(),
                taxYear: taxYear,
                canton: authService.user?.canton,
                amount: processingResult != nil ? extractAmount(from: processingResult!.additionalInfo) : nil,
                taxCategoryType: taxCategoryType,
                currency: "CHF",
                workflowStatus: .pendingClassification
            )

            try await firestoreService.createDocument(document)
            uploadedDocumentId = document.id

            // 4. Show success and clear any warnings
            uploadSuccess = true
            isUploading = false
            warningMessage = nil
            errorMessage = nil

            print("✅ Document uploaded successfully as PDF: \(documentName)")

            // Reset after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                selectedImage = nil
                uploadSuccess = false
                uploadedDocumentId = nil
                aiCategory = nil
                aiConfidence = nil
                extractedText = nil
            }

        } catch {
            print("❌ Upload failed: \(error)")
            errorMessage = "documents.upload.error.upload_failed".localized(with: error.localizedDescription)
            isUploading = false
        }
    }

    // MARK: - Helper Methods

    private func generateDocumentSummary(result: DocumentProcessingResult) -> String {
        var summary = result.suggestedCategory.displayName

        if let date = result.additionalInfo["date"] {
            summary += " " + "document.summary.from".localized(with: date)
        }

        if let amount = result.additionalInfo["amount"] {
            summary += " (\(amount))"
        }

        if let vendor = result.additionalInfo["vendor"] {
            summary += " - \(vendor)"
        } else if let employer = result.additionalInfo["employer"] {
            summary += " - \(employer)"
        }

        return summary
    }

    private func extractAmount(from info: [String: String]) -> Double? {
        guard let amountStr = info["amount"] else { return nil }

        // Remove CHF and formatting
        let cleanedAmount = amountStr
            .replacingOccurrences(of: "CHF", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanedAmount)
    }

    // MARK: - Image Compression

    private func compressImageBelow4MB(image: UIImage) -> UIImage {
        let maxSizeBytes = 4 * 1024 * 1024 // 4MB in bytes
        let maxSizeBytesWithBuffer = Int(Double(maxSizeBytes) * 0.9) // Use 90% to have safety margin

        // Start with high quality
        var compression: CGFloat = 0.9
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return image
        }

        // If already below 4MB, return original
        if imageData.count < maxSizeBytesWithBuffer {
            print("✅ Image size: \(imageData.count / 1024)KB - No compression needed")
            return image
        }

        print("⚠️ Image size: \(imageData.count / 1024)KB - Compressing...")

        // Binary search for optimal compression
        var minCompression: CGFloat = 0.1
        var maxCompression: CGFloat = 0.9

        while maxCompression - minCompression > 0.05 {
            compression = (minCompression + maxCompression) / 2
            guard let data = image.jpegData(compressionQuality: compression) else {
                break
            }
            imageData = data

            if imageData.count > maxSizeBytesWithBuffer {
                maxCompression = compression
            } else {
                minCompression = compression
            }
        }

        // Final check - if still too large, resize image
        if imageData.count > maxSizeBytesWithBuffer {
            print("📐 Still too large (\(imageData.count / 1024)KB), resizing image...")
            let resizedImage = resizeImage(image: image, maxSizeBytes: maxSizeBytesWithBuffer)
            if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                imageData = data
                print("✅ Resized image size: \(imageData.count / 1024)KB")
                return resizedImage
            }
        }

        print("✅ Compressed image size: \(imageData.count / 1024)KB")
        return UIImage(data: imageData) ?? image
    }

    private func resizeImage(image: UIImage, maxSizeBytes: Int) -> UIImage {
        // Calculate scale factor to reduce file size
        let originalSize = image.size
        let scaleFactor = sqrt(Double(maxSizeBytes) / Double(image.jpegData(compressionQuality: 1.0)?.count ?? 1))
        let newSize = CGSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Category Mapping

    /// Map AI-detected TaxDocumentCategory to TaxCategoryType for accurate subcategory tracking
    private func mapToTaxCategoryType(_ category: TaxDocumentCategory?) -> String? {
        guard let category = category else { return nil }

        switch category {
        // Income mappings
        case .lohnausweis:
            return "salary"

        // Deduction mappings
        case .spesenbeleg:
            return "travelExpenses"
        case .krankenArztkosten:
            return "medical"
        case .versicherung:
            return "insurancePremiums"
        case .hypothekarzinsen:
            return "mortgage"
        case .spenden:
            return "donations"
        case .kinderbetreuung:
            return "childcare"
        case .weiterbildung:
            return "education"

        // Pillar/Pension mappings
        case .pensionskasse:
            return "pillar_2"

        // Wealth/Asset mappings
        case .bankStatement:
            return "savings"
        case .vermietung:
            return "rental"

        // Other
        case .steuerrechnung, .other:
            return "other"
        }
    }
}

#Preview {
    DocumentUploadView()
        .environmentObject(AuthenticationService())
}
