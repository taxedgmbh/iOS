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

    // Manual category selection
    @State private var manualCategory: TaxCategoryType?
    @State private var showCategoryPicker = false
    @State private var needsCategorySelection = false

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

                    // Category Selection (natural part of flow)
                    if needsCategorySelection && !uploadSuccess {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.blue)
                                Text("Select Document Category")
                                    .font(.headline)
                            }

                            if let category = manualCategory {
                                // Show selected category
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: category.icon)
                                            .foregroundColor(category.color)
                                            .font(.system(size: 20))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Selected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        showCategoryPicker = true
                                    }) {
                                        Text("Change")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            } else {
                                // Show select button
                                Button(action: {
                                    showCategoryPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "folder.badge.plus")
                                        Text("Choose Category")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
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
                            .background(needsCategorySelection && manualCategory == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(needsCategorySelection && manualCategory == nil)
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
            .sheet(isPresented: $showCategoryPicker) {
                SimpleCategoryPickerView(selectedCategory: $manualCategory)
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
            // 0. Compress image to below 4MB BEFORE processing (on background thread)
            print("🗜️ Compressing image to below 4MB on background thread...")
            image = await compressImageBelow4MB(image: image)
            print("✅ Image compressed successfully")

            // 1. Run AI processing on device (Vision OCR + Categorization)
            // SKIP AI processing if user has already manually selected a category
            var processingResult: DocumentProcessingResult?

            if manualCategory == nil {
                // Only run AI if no manual category selected
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
                    print("📤 User needs to select category manually...")
                    aiProcessingFailed = true
                    processingResult = nil

                    // Quietly require category selection without negative messaging
                    needsCategorySelection = true

                    // Don't continue with upload automatically - wait for category selection
                    return
                }

                // Check if confidence is too low (< 50%)
                if let confidence = processingResult?.confidence, confidence < 0.5 {
                    print("⚠️ AI confidence too low: \(Int(confidence * 100))%")
                    print("📤 User needs to select category manually...")
                    needsCategorySelection = true
                    return
                }
            } else {
                // User has manually selected a category, skip AI processing
                print("📁 Using manually selected category: \(manualCategory!.displayName)")
                print("⏭️ Skipping AI processing")
            }

            // 2. Upload to Firebase Storage as optimized PDF
            isUploading = true

            // Use manual category if selected, otherwise use AI result
            let effectiveCategory: TaxCategoryType?
            if let manual = manualCategory {
                effectiveCategory = manual
                print("📁 Using manually selected category: \(manual.displayName)")
            } else {
                effectiveCategory = mapToTaxCategoryType(processingResult?.suggestedCategory)
                print("🤖 Using AI suggested category")
            }

            // Use document type from manual selection or AI categorization
            let documentType = effectiveCategory?.rawValue ?? "uncategorized"

            // Tax category type for organized storage
            let taxCategoryType = effectiveCategory?.rawValue

            // Get current tax year
            let taxYear = Calendar.current.component(.year, from: Date())

            // Generate attachment number for file labeling
            let uploadDate = Date()
            let attachmentNumber = generateAttachmentNumber(for: effectiveCategory, uploadDate: uploadDate)
            print("📎 Generated attachment number: \(attachmentNumber)")

            // Prepare category info for organized storage
            let categoryRawValue: String
            if let effective = effectiveCategory {
                categoryRawValue = convertCategoryGroupToStoragePath(effective.categoryGroup)
            } else {
                categoryRawValue = "uncategorized"
            }

            let (downloadURL, documentId) = try await storageService.uploadDocumentAsPDF(
                image: image,
                customerId: userId,
                documentType: documentType,
                taxYear: taxYear,
                category: categoryRawValue,
                subcategory: taxCategoryType ?? "",
                attachmentNumber: attachmentNumber
            ) { progress in
                uploadProgress = progress
            }

            print("✅ Received documentId: \(documentId)")

            // 3. Create Firestore document record with AI categorization (if available)
            // Extract document name from URL (UUID_documentType.pdf)
            let urlComponents = downloadURL.components(separatedBy: "/")
            let documentName = urlComponents.last?.removingPercentEncoding ?? "document.pdf"

            // Determine category and subcategory based on whether manual or AI was used
            let finalCategory: TaxCategory
            let finalSubcategory: String?

            if let manual = manualCategory {
                // Manual selection - convert TaxCategoryType to TaxCategory
                finalCategory = convertToTaxCategory(manual)
                finalSubcategory = manual.rawValue
            } else if let aiCat = mapToTaxCategoryType(processingResult?.suggestedCategory) {
                // AI categorization
                finalCategory = convertToTaxCategory(aiCat)
                finalSubcategory = aiCat.rawValue
            } else {
                // Fallback
                finalCategory = .uncategorized
                finalSubcategory = nil
            }

            let document = TaxDocument(
                customerId: userId,
                name: documentName,
                storageUrl: downloadURL,
                category: finalCategory,
                subcategory: finalSubcategory,
                aiConfidence: processingResult?.confidence,
                extractedText: processingResult?.extractedText,
                aiSummary: {
                    if let result = processingResult {
                        return generateDocumentSummary(result: result)
                    } else if manualCategory != nil {
                        return "Manually categorized by user"
                    } else {
                        return "documents.upload.manual_review_required".localized
                    }
                }(),
                status: {
                    if let result = processingResult {
                        return result.confidence > 0.7 ? .pending : .processing
                    } else if manualCategory != nil {
                        return .pending  // Manual categorization - ready for review
                    } else {
                        return .processing  // No categorization
                    }
                }(),
                taxYear: taxYear,
                canton: authService.user?.canton,
                amount: processingResult != nil ? extractAmount(from: processingResult!.additionalInfo) : nil,
                taxCategoryType: taxCategoryType,
                attachmentNumber: attachmentNumber,
                currency: "CHF",
                workflowStatus: manualCategory != nil ? .pendingReview : .pendingClassification
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

    private func compressImageBelow4MB(image: UIImage) async -> UIImage {
        // Run compression on background thread to avoid blocking main thread
        return await Task.detached(priority: .userInitiated) {
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

            print("⚠️ Image size: \(imageData.count / 1024)KB - Compressing on background thread...")

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
                let resizedImage = self.resizeImage(image: image, maxSizeBytes: maxSizeBytesWithBuffer)
                if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                    imageData = data
                    print("✅ Resized image size: \(imageData.count / 1024)KB")
                    return resizedImage
                }
            }

            print("✅ Compressed image size: \(imageData.count / 1024)KB")
            return UIImage(data: imageData) ?? image
        }.value
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

    // MARK: - Attachment Number Generation

    /// Generate attachment number based on category and upload timestamp
    private func generateAttachmentNumber(for categoryType: TaxCategoryType?, uploadDate: Date = Date()) -> String {
        let categoryCode = categoryType?.rawValue ?? "uncategorized"
        let shortCode = getShortCode(for: categoryCode)

        // Use timestamp for uniqueness
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timeStamp = dateFormatter.string(from: uploadDate)
        let lastFour = String(timeStamp.suffix(4))

        return "\(shortCode)_\(lastFour)"
    }

    /// Get short code for category
    private func getShortCode(for category: String) -> String {
        let codeMap: [String: String] = [
            "salary": "SAL",
            "bonus": "BON",
            "freelance": "FRL",
            "investment": "INV",
            "rental": "REN",
            "pension": "PEN",
            "foreignIncome": "FIN",
            "mortgage": "MTG",
            "donations": "DON",
            "education": "EDU",
            "medical": "MED",
            "insurancePremiums": "INS",
            "childcare": "CHI",
            "homeOffice": "HOM",
            "travelExpenses": "TRV",
            "property": "PRO",
            "stocks": "STK",
            "crypto": "CRY",
            "foreignWealth": "FWE",
            "savings": "SAV",
            "insuranceSurrenderValue": "ISV",
            "pillar2": "P2A",
            "pillar3a": "P3A",
            "militaryService": "MIL",
            "taxTreaty": "TAX",
            "other": "OTH",
            "uncategorized": "UNC"
        ]
        return codeMap[category] ?? "DOC"
    }

    // MARK: - Category Mapping

    /// Map AI-detected TaxDocumentCategory to TaxCategoryType for accurate subcategory tracking
    private func mapToTaxCategoryType(_ category: TaxDocumentCategory?) -> TaxCategoryType? {
        guard let category = category else { return nil }

        switch category {
        // Income mappings
        case .lohnausweis:
            return .salary

        // Deduction mappings
        case .spesenbeleg:
            return .travelExpenses
        case .krankenArztkosten:
            return .medical
        case .versicherung:
            return .insurancePremiums
        case .hypothekarzinsen:
            return .mortgage
        case .spenden:
            return .donations
        case .kinderbetreuung:
            return .childcare
        case .weiterbildung:
            return .education

        // Pillar/Pension mappings
        case .pensionskasse:
            return .pillar2

        // Wealth/Asset mappings
        case .bankStatement:
            return .savings
        case .vermietung:
            return .rental

        // Other
        case .steuerrechnung, .other:
            return .other
        }
    }

    /// Convert TaxCategoryType to TaxCategory for TaxDocument model
    private func convertToTaxCategory(_ categoryType: TaxCategoryType) -> TaxCategory {
        switch categoryType.categoryGroup {
        case .income:
            return .income
        case .deductions:
            return .deduction
        case .assets:
            return .wealth
        case .swissSpecific:
            // Map Swiss specific categories
            switch categoryType {
            case .pillar2, .pillar3a:
                return .pillar
            case .militaryService, .taxTreaty:
                return .foreignIncome
            default:
                return .uncategorized
            }
        }
    }

    /// Convert CategoryGroup to storage path string
    private func convertCategoryGroupToStoragePath(_ group: CategoryGroup) -> String {
        switch group {
        case .income:
            return "income"
        case .deductions:
            return "deduction"
        case .assets:
            return "wealth"
        case .swissSpecific:
            return "pillar"
        }
    }
}

// MARK: - Simple Category Picker (Single Selection)
struct SimpleCategoryPickerView: View {
    @Binding var selectedCategory: TaxCategoryType?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // Get all available categories
    private var allCategories: [TaxCategoryType] {
        TaxCategoryType.allCases.filter { $0 != .other }
    }

    private var filteredCategoriesByGroup: [CategoryGroup: [TaxCategoryType]] {
        var grouped: [CategoryGroup: [TaxCategoryType]] = [:]

        let categoriesToShow = searchText.isEmpty ? allCategories :
            allCategories.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }

        for category in categoriesToShow {
            grouped[category.categoryGroup, default: []].append(category)
        }

        return grouped
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search categories", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Categories by group
                    ForEach(CategoryGroup.allCases, id: \.self) { group in
                        if let categories = filteredCategoriesByGroup[group], !categories.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Group header
                                HStack {
                                    Image(systemName: group.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                    Text(group.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal)

                                // Category grid
                                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 8) {
                                    ForEach(categories.sorted { $0.displayName < $1.displayName }, id: \.self) { category in
                                        CategoryOptionButton(
                                            category: category,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                            // Haptic feedback
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            // Dismiss after selection
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Select Document Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Category Option Button
struct CategoryOptionButton: View {
    let category: TaxCategoryType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? category.color.opacity(0.15) : Color(UIColor.systemGray6))
                        .frame(height: 80)

                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(category.color)

                        Text(category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(6)

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                    .font(.title3)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.clear, lineWidth: 2)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DocumentUploadView()
        .environmentObject(AuthenticationService())
}
