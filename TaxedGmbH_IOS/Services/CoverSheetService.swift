//
//  CoverSheetService.swift
//  TaxedGmbH_IOS
//
//  Generates PDF cover sheets for Swiss tax office document submission
//

import Foundation
import PDFKit
import UIKit
import SwiftUI
import FirebaseStorage

@MainActor
class CoverSheetService {
    static let shared = CoverSheetService()

    private let storage = Storage.storage()
    private let firestoreService = FirestoreService.shared

    private init() {}

    // MARK: - Cover Sheet Generation

    /// Generate a PDF cover sheet for a tax document following Swiss tax office requirements
    func generateCoverSheet(
        for document: TaxDocument,
        user: User
    ) async throws -> URL {
        print("📄 Generating cover sheet for document: \(document.name)")

        // Create PDF page with Swiss tax office template
        let pdfData = createCoverSheetPDF(document: document, user: user)

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cover_\(document.id).pdf")

        try pdfData.write(to: tempURL)
        print("✅ Cover sheet PDF created: \(tempURL.path)")

        return tempURL
    }

    /// Merge cover sheet with original document PDF
    func mergeCoverWithDocument(
        coverSheetURL: URL,
        documentURL: URL,
        outputFileName: String
    ) async throws -> URL {
        print("🔗 Merging cover sheet with document")

        guard let coverPDF = PDFDocument(url: coverSheetURL),
              let documentPDF = PDFDocument(url: documentURL) else {
            throw NSError(domain: "CoverSheetService", code: 1001,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF documents"])
        }

        // Create new PDF with cover sheet first
        let mergedPDF = PDFDocument()

        // Add cover sheet page
        if let coverPage = coverPDF.page(at: 0) {
            mergedPDF.insert(coverPage, at: 0)
        }

        // Add all pages from original document
        for pageIndex in 0..<documentPDF.pageCount {
            if let page = documentPDF.page(at: pageIndex) {
                mergedPDF.insert(page, at: mergedPDF.pageCount)
            }
        }

        // Save merged PDF to temp location
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(outputFileName)

        guard mergedPDF.write(to: tempURL) else {
            throw NSError(domain: "CoverSheetService", code: 1002,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to write merged PDF"])
        }

        print("✅ Merged PDF created with \(mergedPDF.pageCount) pages")
        return tempURL
    }

    /// Complete workflow: Generate cover, merge with document, upload to storage, update Firestore
    func processCoverSheet(
        for document: TaxDocument,
        user: User
    ) async throws -> (coverSheetUrl: String, processedDocumentUrl: String) {
        print("🚀 Starting cover sheet processing for: \(document.name)")

        // Step 1: Generate cover sheet
        let coverSheetURL = try await generateCoverSheet(for: document, user: user)

        // Step 2: Download original document from Firebase Storage
        let originalDocumentURL = try await downloadDocument(storageUrl: document.storageUrl)

        // Step 3: Merge cover with original
        let mergedFileName = "processed_\(document.id).pdf"
        let mergedURL = try await mergeCoverWithDocument(
            coverSheetURL: coverSheetURL,
            documentURL: originalDocumentURL,
            outputFileName: mergedFileName
        )

        // Step 4: Upload cover sheet to Firebase Storage
        guard let workspaceId = document.workspaceId else {
            throw NSError(domain: "CoverSheetService", code: 1005,
                         userInfo: [NSLocalizedDescriptionKey: "Workspace ID is required"])
        }

        // Use workspace-centric storage paths
        let coverSheetPath = "workspaces/\(workspaceId)/\(document.taxYear)/\(document.id)/cover_sheet.pdf"
        let coverSheetStorageUrl = try await uploadPDF(
            fileURL: coverSheetURL,
            storagePath: coverSheetPath
        )

        // Step 5: Upload merged document to Firebase Storage
        let processedPath = "workspaces/\(workspaceId)/\(document.taxYear)/\(document.id)/processed.pdf"
        let processedStorageUrl = try await uploadPDF(
            fileURL: mergedURL,
            storagePath: processedPath
        )

        // Step 6: Update Firestore document record
        var updatedDocument = document
        updatedDocument.coverSheetGenerated = true
        updatedDocument.coverSheetUrl = coverSheetStorageUrl
        updatedDocument.processedDocumentUrl = processedStorageUrl
        updatedDocument.workflowStatus = .coverGenerated
        updatedDocument.updatedAt = Date()

        try await firestoreService.updateDocument(updatedDocument)

        // Clean up temp files
        try? FileManager.default.removeItem(at: coverSheetURL)
        try? FileManager.default.removeItem(at: originalDocumentURL)
        try? FileManager.default.removeItem(at: mergedURL)

        print("✅ Cover sheet processing complete")
        return (coverSheetStorageUrl, processedStorageUrl)
    }

    // MARK: - PDF Creation

    private func createCoverSheetPDF(document: TaxDocument, user: User) -> Data {
        // A4 size in points (595.2 x 841.8)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            // Swiss Tax Office Header
            drawHeader(in: pageRect, context: context.cgContext)

            // Get category color for color coding
            let categoryColor = getCategoryColor(document)
            let categoryDisplayName = getCategoryDisplayName(document)

            // Generate attachment number
            let attachmentNumber = document.attachmentNumber ?? generateAttachmentNumber(document)

            // Document Information Section with color indicator
            var yPosition: CGFloat = 120

            // Draw category color indicator
            drawColorIndicator(color: categoryColor, y: yPosition, pageRect: pageRect, context: context.cgContext)

            yPosition = drawSection(
                title: "Dokument Informationen",
                items: [
                    ("Dokument Name", document.name),
                    ("Kategorie", categoryDisplayName),
                    ("Anhang-Nummer", attachmentNumber),
                    ("Steuerjahr", String(document.taxYear)),
                    ("Hochgeladen am", formatDate(document.uploadedAt))
                ],
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // Customer Information Section
            yPosition += 30
            yPosition = drawSection(
                title: "Kundeninformationen",
                items: [
                    ("Name", user.name),
                    ("AHV-Nummer", user.ahvNumber ?? "Nicht angegeben"),
                    ("Kanton", user.canton ?? "Nicht angegeben"),
                    ("Gemeinde", user.municipality ?? "Nicht angegeben"),
                    ("Kunden-ID", user.id ?? "Nicht angegeben")
                ],
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // Document Details Section
            yPosition += 30
            var detailItems: [(String, String)] = []

            if let purpose = document.purpose {
                detailItems.append(("Zweck", purpose))
            }

            if let amount = document.amount {
                let currency = document.currency ?? "CHF"
                let formattedAmount = String(format: "%.2f %@", amount, currency)
                detailItems.append(("Betrag", formattedAmount))
            }

            if let documentDate = document.documentDate {
                detailItems.append(("Dokumentdatum", formatDate(documentDate)))
            }

            if !detailItems.isEmpty {
                yPosition = drawSection(
                    title: "Dokumentdetails",
                    items: detailItems,
                    startY: yPosition,
                    pageRect: pageRect,
                    context: context.cgContext
                )
            }

            // Expert Review Section
            if let expertNotes = document.expertNotes, !expertNotes.isEmpty {
                yPosition += 30
                yPosition = drawNotesSection(
                    title: "Experten-Notizen",
                    notes: expertNotes,
                    startY: yPosition,
                    pageRect: pageRect,
                    context: context.cgContext
                )
            }

            // AI Classification Section
            if let aiConfidence = document.aiConfidence {
                yPosition += 30
                let confidencePercent = String(format: "%.1f%%", aiConfidence * 100)
                yPosition = drawSection(
                    title: "KI-Klassifizierung",
                    items: [
                        ("Vertrauensstufe", confidencePercent),
                        ("Status", document.status.displayName)
                    ],
                    startY: yPosition,
                    pageRect: pageRect,
                    context: context.cgContext
                )
            }

            // Footer
            drawFooter(in: pageRect, context: context.cgContext)
        }

        return pdfData
    }

    // MARK: - PDF Drawing Helpers

    private func drawHeader(in rect: CGRect, context: CGContext) {
        // Red header bar (Swiss theme)
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: rect.width, height: 80))

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let title = "Steuerdokument Deckblatt"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: 40,
            y: 28,
            width: rect.width - 80,
            height: titleSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)

        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let subtitle = "Generiert durch TAXED.CH - \(formatDate(Date()))"
        let subtitleRect = CGRect(
            x: 40,
            y: 52,
            width: rect.width - 80,
            height: 20
        )
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
    }

    private func drawSection(
        title: String,
        items: [(String, String)],
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var yPosition = startY

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let titleRect = CGRect(x: 40, y: yPosition, width: pageRect.width - 80, height: 22)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition += 28

        // Section items
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        for (label, value) in items {
            // Draw label
            let labelRect = CGRect(x: 40, y: yPosition, width: 150, height: 16)
            label.draw(in: labelRect, withAttributes: labelAttributes)

            // Draw value
            let valueRect = CGRect(x: 200, y: yPosition, width: pageRect.width - 240, height: 16)
            value.draw(in: valueRect, withAttributes: valueAttributes)

            yPosition += 22
        }

        return yPosition
    }

    private func drawNotesSection(
        title: String,
        notes: String,
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var yPosition = startY

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let titleRect = CGRect(x: 40, y: yPosition, width: pageRect.width - 80, height: 22)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition += 28

        // Notes box
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1.0)
        let notesBoxRect = CGRect(x: 40, y: yPosition, width: pageRect.width - 80, height: 100)
        context.stroke(notesBoxRect)

        // Notes text
        let notesAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let notesTextRect = CGRect(x: 50, y: yPosition + 10, width: pageRect.width - 100, height: 80)
        notes.draw(in: notesTextRect, withAttributes: notesAttributes)

        return yPosition + 100
    }

    private func drawFooter(in rect: CGRect, context: CGContext) {
        let footerY = rect.height - 100

        // Separator line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 40, y: footerY))
        context.addLine(to: CGPoint(x: rect.width - 40, y: footerY))
        context.strokePath()

        // Disclaimer section
        let disclaimerTitle = "Haftungsausschluss"
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        let disclaimerTitleRect = CGRect(x: 40, y: footerY + 10, width: rect.width - 80, height: 12)
        disclaimerTitle.draw(in: disclaimerTitleRect, withAttributes: disclaimerAttributes)

        // Disclaimer text
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let footerText = """
        Dieses Deckblatt wurde automatisch von TAXED.CH generiert und dient der Organisation Ihrer Steuerunterlagen.
        Bitte reichen Sie es zusammen mit dem Originaldokument beim Steueramt ein.

        Die Anhang-Nummern und Farbcodierung dienen der eindeutigen Identifikation. TAXED.CH übernimmt keine Haftung
        für die Richtigkeit der AI-generierten Kategorisierung. Bitte prüfen Sie alle Angaben vor der Einreichung.
        """
        let footerRect = CGRect(x: 40, y: footerY + 24, width: rect.width - 80, height: 60)
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    // MARK: - Helper Methods

    private func getCategoryDisplayName(_ document: TaxDocument) -> String {
        if let taxCategoryType = document.taxCategoryType,
           let categoryType = TaxCategoryType(rawValue: taxCategoryType) {
            return categoryType.displayName
        }
        return document.category.displayName
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_CH")
        return formatter.string(from: date)
    }

    private func downloadDocument(storageUrl: String) async throws -> URL {
        // Download original document from Firebase Storage
        guard let url = URL(string: storageUrl) else {
            throw NSError(domain: "CoverSheetService", code: 1003,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid storage URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("original_\(UUID().uuidString).pdf")

        try data.write(to: tempURL)
        return tempURL
    }

    private func uploadPDF(fileURL: URL, storagePath: String) async throws -> String {
        let pdfData = try Data(contentsOf: fileURL)
        let storageRef = storage.reference().child(storagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "fileType": "cover_sheet"
        ]

        // Upload with async/await
        _ = try await storageRef.putDataAsync(pdfData, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        print("✅ PDF uploaded to: \(downloadURL.absoluteString)")

        return downloadURL.absoluteString
    }

    // MARK: - Color Coding & Attachment Numbers

    /// Get the category color for color-coded visual identification
    private func getCategoryColor(_ document: TaxDocument) -> UIColor {
        // Try to get TaxCategoryType from subcategory
        if let taxCategoryType = document.taxCategoryType,
           let categoryType = TaxCategoryType(rawValue: taxCategoryType) {
            // Convert SwiftUI Color to UIColor
            return convertToUIColor(categoryType.color)
        }
        // Fallback to gray for uncategorized
        return UIColor.gray
    }

    /// Convert SwiftUI Color to UIColor
    private func convertToUIColor(_ color: Color) -> UIColor {
        // Use UIColor init from SwiftUI Color
        return UIColor(color)
    }

    /// Generate attachment number based on category and subcategory
    private func generateAttachmentNumber(_ document: TaxDocument) -> String {
        // Get category/subcategory short codes
        let categoryCode = document.taxCategoryType ?? document.category.rawValue
        let shortCode = getShortCode(categoryCode)

        // For now, use a simple counter based on upload time
        // In a real app, you'd query Firestore to get the count of documents with the same category
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timeStamp = dateFormatter.string(from: document.uploadedAt)
        let lastFour = String(timeStamp.suffix(4))

        return "\(shortCode)_\(lastFour)"
    }

    /// Get short code for category
    private func getShortCode(_ category: String) -> String {
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

    /// Draw color indicator bar on the left side
    private func drawColorIndicator(color: UIColor, y: CGFloat, pageRect: CGRect, context: CGContext) {
        context.setFillColor(color.cgColor)
        let indicatorRect = CGRect(x: 10, y: y, width: 8, height: 100)
        context.fill(indicatorRect)
    }

    // MARK: - Tax Submission Package Generation

    /// Generate complete tax submission package: Title page + Cover letter + All documents with cover sheets
    func generateTaxSubmissionPackage(
        for documents: [TaxDocument],
        user: User,
        workspaceId: String,
        taxYear: Int
    ) async throws -> URL {
        print("📦 Starting tax submission package generation")
        print("   Documents: \(documents.count)")
        print("   Tax Year: \(taxYear)")

        // Step 1: Generate title page
        let titlePageURL = try await generateTitlePage(
            user: user,
            taxYear: taxYear,
            documentCount: documents.count
        )

        // Step 2: Generate cover letter
        let coverLetterURL = try await generateCoverLetter(
            user: user,
            taxYear: taxYear,
            documentCount: documents.count
        )

        // Step 3: Collect all processed documents (cover sheet + original)
        var processedDocuments: [(document: TaxDocument, url: URL)] = []

        for document in documents.sorted(by: {
            ($0.attachmentNumber ?? "") < ($1.attachmentNumber ?? "")
        }) {
            // If processed PDF exists, use it; otherwise generate it
            if let processedUrl = document.processedDocumentUrl,
               let url = URL(string: processedUrl) {
                let tempURL = try await downloadDocument(storageUrl: processedUrl)
                processedDocuments.append((document, tempURL))
            } else {
                // Generate cover sheet and merge with original
                let coverSheetURL = try await generateCoverSheet(for: document, user: user)
                let originalURL = try await downloadDocument(storageUrl: document.storageUrl)
                let mergedURL = try await mergeCoverWithDocument(
                    coverSheetURL: coverSheetURL,
                    documentURL: originalURL,
                    outputFileName: "processed_\(document.id).pdf"
                )
                processedDocuments.append((document, mergedURL))
            }
        }

        // Step 4: Merge everything into final package
        let packageURL = try await mergePackage(
            titlePage: titlePageURL,
            coverLetter: coverLetterURL,
            processedDocuments: processedDocuments.map { $0.url }
        )

        // Step 5: Upload package to storage
        let packagePath = "workspaces/\(workspaceId)/\(taxYear)/tax_submission_package_\(taxYear).pdf"
        let packageStorageUrl = try await uploadPDF(
            fileURL: packageURL,
            storagePath: packagePath
        )

        print("✅ Tax submission package generated: \(packageStorageUrl)")

        // Clean up temp files
        try? FileManager.default.removeItem(at: titlePageURL)
        try? FileManager.default.removeItem(at: coverLetterURL)
        for (_, url) in processedDocuments {
            try? FileManager.default.removeItem(at: url)
        }

        return packageURL
    }

    /// Generate title page for tax submission
    private func generateTitlePage(
        user: User,
        taxYear: Int,
        documentCount: Int
    ) async throws -> URL {
        print("📄 Generating title page")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            // Swiss flag red background header
            context.cgContext.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: 200))

            // White Swiss cross
            drawSwissCross(in: CGRect(x: pageRect.width/2 - 40, y: 60, width: 80, height: 80), context: context.cgContext)

            // Main title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let title = "Steuererklärung \(taxYear)"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (pageRect.width - titleSize.width) / 2,
                y: 160,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)

            // User information section
            var yPosition: CGFloat = 260

            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            let userName = user.name
            let nameRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 30)
            userName.draw(in: nameRect, withAttributes: nameAttributes)
            yPosition += 50

            // User details
            let detailAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            let details = [
                "AHV-Nummer: \(user.ahvNumber ?? "Nicht angegeben")",
                "Kanton: \(user.canton ?? "Nicht angegeben")",
                "Gemeinde: \(user.municipality ?? "Nicht angegeben")",
                "E-Mail: \(user.email)"
            ]

            for detail in details {
                let detailRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 20)
                detail.draw(in: detailRect, withAttributes: detailAttributes)
                yPosition += 25
            }

            // Document summary
            yPosition += 40
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            let summary = "Eingereichte Dokumente"
            let summaryRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 25)
            summary.draw(in: summaryRect, withAttributes: summaryAttributes)
            yPosition += 35

            let countAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let countText = "Anzahl der Belege: \(documentCount)"
            let countRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 22)
            countText.draw(in: countRect, withAttributes: countAttributes)

            // Footer
            let footerY = pageRect.height - 80
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let footer = "Erstellt mit TAXED.CH am \(formatDate(Date()))"
            let footerRect = CGRect(x: 80, y: footerY, width: pageRect.width - 160, height: 20)
            footer.draw(in: footerRect, withAttributes: footerAttributes)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("title_page_\(taxYear).pdf")
        try pdfData.write(to: tempURL)

        print("✅ Title page created")
        return tempURL
    }

    /// Generate cover letter for customer
    private func generateCoverLetter(
        user: User,
        taxYear: Int,
        documentCount: Int
    ) async throws -> URL {
        print("📄 Generating cover letter")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 100

            // TAXED.CH Logo/Header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            ]
            let header = "TAXED.CH"
            let headerRect = CGRect(x: 60, y: yPosition, width: 200, height: 25)
            header.draw(in: headerRect, withAttributes: headerAttributes)
            yPosition += 60

            // Date
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let dateText = formatDate(Date())
            let dateRect = CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 20)
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
            yPosition += 60

            // Recipient
            let recipientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let recipient = """
            \(user.name)
            \(user.canton ?? "")
            """
            let recipientRect = CGRect(x: 60, y: yPosition, width: 300, height: 50)
            recipient.draw(in: recipientRect, withAttributes: recipientAttributes)
            yPosition += 80

            // Subject
            let subjectAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let subject = "Steuererklärung \(taxYear) - Dokumentenübermittlung"
            let subjectRect = CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 22)
            subject.draw(in: subjectRect, withAttributes: subjectAttributes)
            yPosition += 50

            // Letter body
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 6
                    return style
                }()
            ]

            let body = """
            Sehr geehrte Damen und Herren,

            Anbei übermitteln wir Ihnen die Steuererklärung für das Steuerjahr \(taxYear).

            Das vorliegende Dossier enthält \(documentCount) Belege, die wie folgt organisiert sind:

            • Jeder Beleg ist mit einem Deckblatt versehen
            • Die Dokumente sind nach Kategorie und Anhang-Nummer sortiert
            • Alle relevanten Informationen sind auf den Deckblättern ersichtlich

            Die Unterlagen wurden sorgfältig geprüft und kategorisiert. Bei Rückfragen stehen wir Ihnen gerne zur Verfügung.

            Mit freundlichen Grüssen,

            TAXED.CH
            Ihr digitaler Steuerassistent
            """

            let bodyRect = CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 400)
            body.draw(in: bodyRect, withAttributes: bodyAttributes)

            // Footer
            let footerY = pageRect.height - 60
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: 60, y: footerY))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 60, y: footerY))
            context.cgContext.strokePath()

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let footer = "TAXED.CH | Automatisierte Steuerbelegerstellung | www.taxed.ch"
            let footerRect = CGRect(x: 60, y: footerY + 10, width: pageRect.width - 120, height: 15)
            footer.draw(in: footerRect, withAttributes: footerAttributes)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cover_letter_\(taxYear).pdf")
        try pdfData.write(to: tempURL)

        print("✅ Cover letter created")
        return tempURL
    }

    /// Merge all PDFs into final package
    private func mergePackage(
        titlePage: URL,
        coverLetter: URL,
        processedDocuments: [URL]
    ) async throws -> URL {
        print("🔗 Merging package PDFs")

        let mergedPDF = PDFDocument()
        var pageCount = 0

        // Add title page
        if let titlePDF = PDFDocument(url: titlePage) {
            for i in 0..<titlePDF.pageCount {
                if let page = titlePDF.page(at: i) {
                    mergedPDF.insert(page, at: pageCount)
                    pageCount += 1
                }
            }
        }

        // Add cover letter
        if let letterPDF = PDFDocument(url: coverLetter) {
            for i in 0..<letterPDF.pageCount {
                if let page = letterPDF.page(at: i) {
                    mergedPDF.insert(page, at: pageCount)
                    pageCount += 1
                }
            }
        }

        // Add all processed documents
        for documentURL in processedDocuments {
            if let docPDF = PDFDocument(url: documentURL) {
                for i in 0..<docPDF.pageCount {
                    if let page = docPDF.page(at: i) {
                        mergedPDF.insert(page, at: pageCount)
                        pageCount += 1
                    }
                }
            }
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tax_package_\(UUID().uuidString).pdf")

        guard mergedPDF.write(to: tempURL) else {
            throw NSError(domain: "CoverSheetService", code: 1006,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to write merged package PDF"])
        }

        print("✅ Package merged with \(pageCount) total pages")
        return tempURL
    }

    /// Draw Swiss cross (white cross on transparent background)
    private func drawSwissCross(in rect: CGRect, context: CGContext) {
        context.setFillColor(UIColor.white.cgColor)

        let crossWidth = rect.width * 0.25
        let crossLength = rect.width * 0.8

        // Horizontal bar
        let horizontalRect = CGRect(
            x: rect.minX + (rect.width - crossLength) / 2,
            y: rect.minY + (rect.height - crossWidth) / 2,
            width: crossLength,
            height: crossWidth
        )
        context.fill(horizontalRect)

        // Vertical bar
        let verticalRect = CGRect(
            x: rect.minX + (rect.width - crossWidth) / 2,
            y: rect.minY + (rect.height - crossLength) / 2,
            width: crossWidth,
            height: crossLength
        )
        context.fill(verticalRect)
    }
}
