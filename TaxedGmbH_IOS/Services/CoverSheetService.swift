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
import CoreImage.CIFilterBuiltins

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
        let pdfData = await createCoverSheetPDF(document: document, user: user)

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

    /// Merge cover sheet with original document and add category-colored decorations to document pages
    func mergeCoverWithDocumentEnhanced(
        coverSheetURL: URL,
        documentURL: URL,
        outputFileName: String,
        document: TaxDocument,
        categoryColor: UIColor,
        categoryDisplayName: String,
        attachmentNumber: String
    ) async throws -> URL {
        print("🔗 Merging cover sheet with enhanced document pages")

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

        // Add enhanced pages from original document with category-colored borders and badges
        for pageIndex in 0..<documentPDF.pageCount {
            if let originalPage = documentPDF.page(at: pageIndex) {
                // Create enhanced page with colored decorations
                let enhancedPage = createEnhancedDocumentPage(
                    originalPage: originalPage,
                    categoryColor: categoryColor,
                    categoryDisplayName: categoryDisplayName,
                    attachmentNumber: attachmentNumber,
                    pageNumber: pageIndex + 1,
                    totalPages: documentPDF.pageCount
                )
                mergedPDF.insert(enhancedPage, at: mergedPDF.pageCount)
            }
        }

        // Save merged PDF to temp location
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(outputFileName)

        guard mergedPDF.write(to: tempURL) else {
            throw NSError(domain: "CoverSheetService", code: 1002,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to write merged PDF"])
        }

        print("✅ Enhanced merged PDF created with \(mergedPDF.pageCount) pages")
        return tempURL
    }

    /// Create an enhanced document page with category-colored badge and border
    private func createEnhancedDocumentPage(
        originalPage: PDFPage,
        categoryColor: UIColor,
        categoryDisplayName: String,
        attachmentNumber: String,
        pageNumber: Int,
        totalPages: Int
    ) -> PDFPage {
        let pageRect = originalPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            // Draw original page content first
            context.cgContext.saveGState()
            originalPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()

            // Add category-colored decorations on top
            let margin: CGFloat = 30
            let topMargin: CGFloat = 50

            // Draw thick colored border around the page
            context.cgContext.setStrokeColor(categoryColor.cgColor)
            context.cgContext.setLineWidth(4.0)
            let borderRect = CGRect(
                x: margin,
                y: margin,
                width: pageRect.width - 2 * margin,
                height: pageRect.height - 2 * margin
            )
            context.cgContext.stroke(borderRect)

            // Draw category-colored badge at top-left with attachment number
            let badgeX = margin + 10
            let badgeY = topMargin
            let badgeWidth: CGFloat = 120
            let badgeHeight: CGFloat = 32

            // Badge background (category color)
            context.cgContext.setFillColor(categoryColor.cgColor)
            let badgePath = UIBezierPath(
                roundedRect: CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight),
                cornerRadius: 6
            )
            context.cgContext.addPath(badgePath.cgPath)
            context.cgContext.fillPath()

            // Badge text (white)
            let badgeTextAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let badgeTextSize = attachmentNumber.size(withAttributes: badgeTextAttributes)
            let badgeTextRect = CGRect(
                x: badgeX + (badgeWidth - badgeTextSize.width) / 2,
                y: badgeY + (badgeHeight - badgeTextSize.height) / 2,
                width: badgeTextSize.width,
                height: badgeTextSize.height
            )
            attachmentNumber.draw(in: badgeTextRect, withAttributes: badgeTextAttributes)

            // Draw category name centered at top
            let categoryNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: categoryColor
            ]
            let categoryNameSize = categoryDisplayName.size(withAttributes: categoryNameAttributes)
            let categoryNameRect = CGRect(
                x: (pageRect.width - categoryNameSize.width) / 2,
                y: topMargin + (badgeHeight - categoryNameSize.height) / 2,
                width: categoryNameSize.width,
                height: categoryNameSize.height
            )

            // Draw white background behind category name for better visibility
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            let categoryBgRect = CGRect(
                x: categoryNameRect.minX - 10,
                y: categoryNameRect.minY - 4,
                width: categoryNameRect.width + 20,
                height: categoryNameRect.height + 8
            )
            context.cgContext.fill(categoryBgRect)

            categoryDisplayName.draw(in: categoryNameRect, withAttributes: categoryNameAttributes)

            // Draw page number at bottom-right
            let pageNumberText = "Seite \(pageNumber)/\(totalPages)"
            let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: categoryColor
            ]
            let pageNumberSize = pageNumberText.size(withAttributes: pageNumberAttributes)
            let pageNumberRect = CGRect(
                x: pageRect.width - margin - pageNumberSize.width - 10,
                y: pageRect.height - margin - 15,
                width: pageNumberSize.width,
                height: pageNumberSize.height
            )

            // White background for page number
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            let pageNumBgRect = CGRect(
                x: pageNumberRect.minX - 6,
                y: pageNumberRect.minY - 2,
                width: pageNumberRect.width + 12,
                height: pageNumberRect.height + 4
            )
            context.cgContext.fill(pageNumBgRect)

            pageNumberText.draw(in: pageNumberRect, withAttributes: pageNumberAttributes)
        }

        // Create a new PDF page from the enhanced data
        if let pdfDocument = PDFDocument(data: pdfData),
           let enhancedPage = pdfDocument.page(at: 0) {
            return enhancedPage
        }

        // Fallback: return original page if enhancement fails
        return originalPage
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

        // Step 3: Get category information for enhanced decorations
        let categoryColor = getCategoryColor(document)
        let categoryDisplayName = getCategoryDisplayName(document)
        let attachmentNumber = document.attachmentNumber ?? generateAttachmentNumber(document)

        // Step 3: Merge cover with original using enhanced version with colored borders and badges
        let mergedFileName = "processed_\(document.id).pdf"
        let mergedURL = try await mergeCoverWithDocumentEnhanced(
            coverSheetURL: coverSheetURL,
            documentURL: originalDocumentURL,
            outputFileName: mergedFileName,
            document: document,
            categoryColor: categoryColor,
            categoryDisplayName: categoryDisplayName,
            attachmentNumber: attachmentNumber
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

    private func createCoverSheetPDF(document: TaxDocument, user: User) async -> Data {
        // A4 size in points (595.2 x 841.8)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // Query tax index from TaxIndexService
        var taxIndex: TaxIndexMapping? = nil
        if let canton = user.canton,
           let taxCategoryType = document.taxCategoryType,
           let categoryType = TaxCategoryType(rawValue: taxCategoryType) {
            do {
                taxIndex = try await TaxIndexService.shared.getIndexMapping(
                    canton: canton,
                    category: categoryType,
                    person: nil
                )
                if let index = taxIndex {
                    print("✅ Retrieved tax index: \(canton)-\(index.index) for category: \(categoryType.displayName)")
                } else {
                    print("⚠️ No tax index found for: \(canton) - \(categoryType.displayName)")
                }
            } catch {
                print("❌ Error querying tax index: \(error)")
            }
        }

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            // Swiss Tax Office Header with Canton Badge
            drawHeader(in: pageRect, context: context.cgContext, canton: user.canton)

            // Get category color for color coding
            let categoryColor = getCategoryColor(document)
            let categoryDisplayName = getCategoryDisplayName(document)

            // Generate attachment number
            let attachmentNumber = document.attachmentNumber ?? generateAttachmentNumber(document)

            // Large Category-Colored Info Box (prominent display)
            var yPosition: CGFloat = 100
            yPosition = drawCategoryInfoBox(
                taxIndex: taxIndex,
                document: document,
                user: user,
                categoryColor: categoryColor,
                categoryDisplayName: categoryDisplayName,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // Document Information Section
            yPosition += 20

            // Build document information items
            var documentItems: [(String, String)] = [
                ("Dokument Name", document.name),
                ("Kategorie", categoryDisplayName),
                ("Anhang-Nummer", attachmentNumber)
            ]

            // Add tax index if available
            if let index = taxIndex,
               let canton = user.canton {
                documentItems.append(("Steuerindex", "\(canton)-\(index.index)"))
            }

            documentItems.append(contentsOf: [
                ("Steuerjahr", String(document.taxYear)),
                ("Hochgeladen am", formatDate(document.uploadedAt))
            ])

            yPosition = drawSection(
                title: "DOCUMENT INFORMATION",
                items: documentItems,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext,
                icon: "📄"
            )

            // Customer Information Section with Person 1 & Person 2
            yPosition += 30

            var customerItems: [(String, String)] = []

            // Person 1 (always present)
            let person1Name = user.person1Name ?? user.name
            let person1AHV = user.person1AhvNumber ?? user.ahvNumber ?? "N/A"
            customerItems.append(("Person 1", "\(person1Name) - AHV: \(person1AHV)"))

            // Person 2 (if joint filing)
            if let person2Name = user.person2Name, !person2Name.isEmpty {
                let person2AHV = user.person2AhvNumber ?? "N/A"
                customerItems.append(("Person 2", "\(person2Name) - AHV: \(person2AHV)"))
            }

            // Address
            let addressLine = "\(user.street ?? ""), \(user.postalCode ?? "") \(user.city ?? "") (\(user.canton ?? ""))"
            customerItems.append(("Adresse", addressLine))

            // Other info
            customerItems.append(("Gemeinde", user.municipality ?? "Nicht angegeben"))
            customerItems.append(("E-Mail", user.email))
            if let phone = user.phone, !phone.isEmpty {
                customerItems.append(("Telefon", phone))
            }

            yPosition = drawSection(
                title: "CUSTOMER INFORMATION",
                items: customerItems,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext,
                icon: "👤"
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

            // Bottom Section: QR Code (Left) | Customer ID (Center) | Barcode (Right)
            let bottomY = pageRect.height - 180
            drawBottomSection(
                document: document,
                user: user,
                taxIndex: taxIndex,
                attachmentNumber: attachmentNumber,
                bottomY: bottomY,
                pageRect: pageRect,
                context: context.cgContext
            )

            // Footer with Professional Disclaimer
            drawFooter(in: pageRect, context: context.cgContext)
        }

        return pdfData
    }

    // MARK: - PDF Drawing Helpers

    private func drawHeader(in rect: CGRect, context: CGContext, canton: String?) {
        // Red header bar (Swiss theme)
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: rect.width, height: 80))

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let title = "Steuerdokument Zwischenblatt"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: 40,
            y: 28,
            width: rect.width - 180,
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
            width: rect.width - 180,
            height: 20
        )
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)

        // Canton Badge (Swiss shield in top-right)
        if let canton = canton {
            drawCantonBadge(canton: canton, rect: rect, context: context)
        }
    }

    private func drawCantonBadge(canton: String, rect: CGRect, context: CGContext) {
        let badgeX = rect.width - 90
        let badgeY: CGFloat = 20
        let badgeSize: CGFloat = 60

        // Draw blue circle
        context.setFillColor(red: 0/255, green: 102/255, blue: 204/255, alpha: 1.0)
        let circlePath = UIBezierPath(ovalIn: CGRect(x: badgeX, y: badgeY, width: badgeSize, height: badgeSize))
        context.addPath(circlePath.cgPath)
        context.fillPath()

        // Draw canton text in white
        let cantonAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let cantonSize = canton.size(withAttributes: cantonAttributes)
        let cantonRect = CGRect(
            x: badgeX + (badgeSize - cantonSize.width) / 2,
            y: badgeY + (badgeSize - cantonSize.height) / 2,
            width: cantonSize.width,
            height: cantonSize.height
        )
        canton.draw(in: cantonRect, withAttributes: cantonAttributes)
    }

    private func drawCategoryInfoBox(
        taxIndex: TaxIndexMapping?,
        document: TaxDocument,
        user: User,
        categoryColor: UIColor,
        categoryDisplayName: String,
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var y = startY
        let leftMargin: CGFloat = 60
        let boxHeight: CGFloat = 90
        let boxRect = CGRect(x: leftMargin, y: y, width: pageRect.width - 2 * leftMargin, height: boxHeight)

        // Draw white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(boxRect)

        // Draw thick colored border (3-4px)
        context.setStrokeColor(categoryColor.cgColor)
        context.setLineWidth(3.5)
        context.stroke(boxRect)

        // Line 1: "Ziffer [index] · Person [1/2] · [person name]"
        let line1Text: String
        if let index = taxIndex, let canton = user.canton {
            let personName = user.person1Name ?? user.name
            line1Text = "Ziffer \(index.index) · Person 1 · \(personName)"
        } else {
            line1Text = "Person 1 · \(user.person1Name ?? user.name)"
        }

        let line1Attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: categoryColor
        ]
        let line1Rect = CGRect(x: leftMargin + 15, y: y + 15, width: boxRect.width - 30, height: 25)
        line1Text.draw(in: line1Rect, withAttributes: line1Attributes)

        // Line 2: "[Category Group] · [Category Name]"
        let categoryGroup = getCategoryGroup(document)
        let line2Text = "\(categoryGroup) · \(categoryDisplayName)"
        let line2Attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let line2Rect = CGRect(x: leftMargin + 15, y: y + 42, width: boxRect.width - 30, height: 20)
        line2Text.draw(in: line2Rect, withAttributes: line2Attributes)

        // Line 3: "Formtyp: Hauptformular    Periode: [year]"
        let line3Text = "Formtyp: Hauptformular    Periode: \(document.taxYear)"
        let line3Attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let line3Rect = CGRect(x: leftMargin + 15, y: y + 64, width: boxRect.width - 30, height: 18)
        line3Text.draw(in: line3Rect, withAttributes: line3Attributes)

        return y + boxHeight + 10
    }

    private func getCategoryGroup(_ document: TaxDocument) -> String {
        if let taxCategoryType = document.taxCategoryType,
           let categoryType = TaxCategoryType(rawValue: taxCategoryType) {
            switch categoryType.categoryGroup {
            case .income: return "Einkommen"
            case .deductions: return "Abzüge"
            case .assets: return "Vermögen"
            case .liabilities: return "Schulden"
            case .swissSpecific: return "Schweizer Spezifisch"
            }
        }
        return "Sonstiges"
    }

    private func drawSection(
        title: String,
        items: [(String, String)],
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext,
        icon: String? = nil
    ) -> CGFloat {
        var yPosition = startY

        // Section title with optional icon
        var titleXOffset: CGFloat = 40

        if let iconText = icon {
            // Draw icon (emoji)
            let iconAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular)
            ]
            let iconRect = CGRect(x: 65, y: yPosition, width: 30, height: 22)
            iconText.draw(in: iconRect, withAttributes: iconAttributes)
            titleXOffset = 95
        }

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let titleRect = CGRect(x: titleXOffset, y: yPosition, width: pageRect.width - titleXOffset - 40, height: 22)
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

    private func drawBottomSection(
        document: TaxDocument,
        user: User,
        taxIndex: TaxIndexMapping?,
        attachmentNumber: String,
        bottomY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) {
        let leftMargin: CGFloat = 60
        let rightMargin = pageRect.width - 60

        // LEFT: QR Code with "Dokument-ID" label
        if let qrCode = generateQRCode(document: document, user: user, taxIndex: taxIndex) {
            let qrSize: CGFloat = 80
            let qrX = leftMargin + 20
            drawCode(image: qrCode, x: qrX, y: bottomY, size: qrSize, context: context)

            // Label below QR code
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let labelRect = CGRect(x: qrX - 10, y: bottomY + qrSize + 5, width: qrSize + 20, height: 14)
            "Dokument-ID".draw(in: labelRect, withAttributes: labelAttributes)
        }

        // CENTER: Customer ID
        let customerIdText = "Kunden-ID: \(user.id ?? "")"
        let customerIdAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        let customerIdSize = customerIdText.size(withAttributes: customerIdAttributes)
        let customerIdRect = CGRect(
            x: (pageRect.width - customerIdSize.width) / 2,
            y: bottomY + 30,
            width: customerIdSize.width,
            height: customerIdSize.height
        )
        customerIdText.draw(in: customerIdRect, withAttributes: customerIdAttributes)

        // RIGHT: Barcode with "Beilage: [attachment]" label
        if let barcode = generateBarcode(documentId: document.id) {
            let barcodeWidth: CGFloat = 140
            let barcodeHeight: CGFloat = 45
            let barcodeX = rightMargin - barcodeWidth - 20
            drawCode(image: barcode, x: barcodeX, y: bottomY, size: CGSize(width: barcodeWidth, height: barcodeHeight), context: context)

            // Label below barcode
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let labelText = "Beilage: \(attachmentNumber)"
            let labelRect = CGRect(x: barcodeX, y: bottomY + barcodeHeight + 5, width: barcodeWidth, height: 14)
            labelText.draw(in: labelRect, withAttributes: labelAttributes)
        }
    }

    private func drawFooter(in rect: CGRect, context: CGContext) {
        let footerY = rect.height - 120

        // Separator line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 60, y: footerY))
        context.addLine(to: CGPoint(x: rect.width - 60, y: footerY))
        context.strokePath()

        // Disclaimer section
        let disclaimerTitle = "Haftungsausschluss"
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let disclaimerTitleRect = CGRect(x: 60, y: footerY + 10, width: rect.width - 120, height: 12)
        disclaimerTitle.draw(in: disclaimerTitleRect, withAttributes: disclaimerAttributes)

        // Professional German legal disclaimer text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .justified

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        let footerText = """
        Dieses Zwischenblatt dient ausschliesslich der organisatorischen Strukturierung der eingereichten Steuerunterlagen und begründet keinerlei steuerrechtliche Ansprüche. Es stellt weder eine verbindliche steuerliche Beurteilung noch eine rechtsverbindliche Auskunft dar. Für die materiellrechtliche Richtigkeit, die Vollständigkeit der Angaben sowie die korrekte steuerliche Qualifikation bleibt der Steuerpflichtige allein verantwortlich.
        """
        let footerRect = CGRect(x: 60, y: footerY + 24, width: rect.width - 120, height: 80)
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
        guard !storageUrl.isEmpty else {
            throw NSError(domain: "CoverSheetService", code: 1003,
                         userInfo: [NSLocalizedDescriptionKey: "Empty storage URL"])
        }

        // Determine if it's a full URL or a storage path
        let storageRef: StorageReference
        if let urlObject = URL(string: storageUrl),
           let scheme = urlObject.scheme,
           ["gs", "http", "https"].contains(scheme) {
            // Full URL with scheme
            print("📥 Downloading from URL: \(storageUrl)")
            storageRef = storage.reference(forURL: storageUrl)
        } else {
            // Storage path - need to create reference
            print("📥 Downloading from path: \(storageUrl)")
            storageRef = storage.reference().child(storageUrl)
        }

        // Download data directly from Firebase Storage (more reliable than getting download URL)
        let maxSize: Int64 = 50 * 1024 * 1024 // 50MB
        let data = try await storageRef.data(maxSize: maxSize)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("original_\(UUID().uuidString).pdf")

        try data.write(to: tempURL)
        print("✅ Downloaded document to: \(tempURL)")
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

        // Step 0: Calculate category breakdown for professional documents
        let categoryBreakdown = calculateCategoryBreakdown(documents: documents)

        // Step 1: Generate professional title page with category breakdown
        let titlePageURL = try await generateTitlePage(
            user: user,
            taxYear: taxYear,
            documentCount: documents.count,
            categoryBreakdown: categoryBreakdown
        )

        // Step 2: Generate professional cover letter with category breakdown
        let coverLetterURL = try await generateCoverLetter(
            user: user,
            taxYear: taxYear,
            documentCount: documents.count,
            categoryBreakdown: categoryBreakdown
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
                // Generate cover sheet and merge with original using enhanced version
                let coverSheetURL = try await generateCoverSheet(for: document, user: user)
                let originalURL = try await downloadDocument(storageUrl: document.storageUrl)

                // Get category information for enhanced decorations
                let categoryColor = getCategoryColor(document)
                let categoryDisplayName = getCategoryDisplayName(document)
                let attachmentNumber = document.attachmentNumber ?? generateAttachmentNumber(document)

                let mergedURL = try await mergeCoverWithDocumentEnhanced(
                    coverSheetURL: coverSheetURL,
                    documentURL: originalURL,
                    outputFileName: "processed_\(document.id).pdf",
                    document: document,
                    categoryColor: categoryColor,
                    categoryDisplayName: categoryDisplayName,
                    attachmentNumber: attachmentNumber
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

    /// Calculate category breakdown for documents
    private func calculateCategoryBreakdown(documents: [TaxDocument]) -> [(category: String, count: Int, amount: Double?)] {
        // Group documents by category group
        var categoryGroups: [String: [TaxDocument]] = [:]

        for document in documents {
            var categoryName = "Sonstiges"

            if let taxCategoryType = document.taxCategoryType,
               let categoryType = TaxCategoryType(rawValue: taxCategoryType) {
                switch categoryType.categoryGroup {
                case .income:
                    categoryName = "Einkommen"
                case .deductions:
                    categoryName = "Abzüge"
                case .assets:
                    categoryName = "Vermögen"
                case .liabilities:
                    categoryName = "Schulden"
                case .swissSpecific:
                    categoryName = "Schweizer Spezifisch"
                }
            } else {
                // Fallback to category enum
                switch document.category {
                case .income:
                    categoryName = "Einkommen"
                case .deduction:
                    categoryName = "Abzüge"
                case .pillar:
                    categoryName = "Vorsorge (Pillar 2/3)"
                case .wealth:
                    categoryName = "Vermögen"
                case .foreignIncome, .foreignPension, .foreignWealth, .taxTreaty, .foreignTax:
                    categoryName = "Ausländische Einkünfte"
                case .uncategorized:
                    categoryName = "Unkategorisiert"
                }
            }

            if categoryGroups[categoryName] == nil {
                categoryGroups[categoryName] = []
            }
            categoryGroups[categoryName]?.append(document)
        }

        // Build breakdown array with counts
        var breakdown: [(category: String, count: Int, amount: Double?)] = []

        // Sort by category name for consistent ordering
        let sortedCategories = categoryGroups.keys.sorted()

        for category in sortedCategories {
            if let docs = categoryGroups[category] {
                let count = docs.count

                // Calculate total amount if available
                let totalAmount = docs.compactMap { $0.amount }.reduce(0, +)
                let amount = totalAmount > 0 ? totalAmount : nil

                breakdown.append((category: category, count: count, amount: amount))
            }
        }

        // If no categories found, add a default entry
        if breakdown.isEmpty {
            breakdown.append((category: "Alle Dokumente", count: documents.count, amount: nil))
        }

        return breakdown
    }

    /// Generate professional consulting-style title page for tax submission
    private func generateTitlePage(
        user: User,
        taxYear: Int,
        documentCount: Int,
        categoryBreakdown: [(category: String, count: Int, amount: Double?)]
    ) async throws -> URL {
        print("📄 Generating professional title page")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 60

            // MARK: - Professional Header
            // TAXED.CH logo/branding
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            ]
            "TAXED.CH".draw(in: CGRect(x: 60, y: yPosition, width: 300, height: 35), withAttributes: logoAttributes)

            // Classification
            let classificationAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.gray
            ]
            let classification = "Steuerpaket | Vertraulich"
            let classSize = classification.size(withAttributes: classificationAttributes)
            classification.draw(in: CGRect(x: pageRect.width - 60 - classSize.width, y: yPosition + 5, width: classSize.width, height: 20), withAttributes: classificationAttributes)

            // Swiss red accent line
            yPosition += 50
            context.cgContext.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            context.cgContext.setLineWidth(2.0)
            context.cgContext.move(to: CGPoint(x: 60, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 60, y: yPosition))
            context.cgContext.strokePath()

            // MARK: - Main Title Section
            yPosition += 40
            let mainTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "STEUERERKLÄRUNG".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 45), withAttributes: mainTitleAttributes)

            yPosition += 50
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            "Steuerjahr \(taxYear) 🇨🇭".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 30), withAttributes: subtitleAttributes)

            // Reference number
            yPosition += 35
            let refAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            ]
            let userIdShort = String((user.id ?? "XXXXXX").prefix(6)).uppercased()
            let refNumber = "Ref: TAX-\(taxYear)-\(userIdShort)"
            refNumber.draw(in: CGRect(x: 60, y: yPosition, width: 300, height: 18), withAttributes: refAttributes)

            // Date prepared
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let dateText = "Erstellt: \(formatDate(Date()))"
            let dateSize = dateText.size(withAttributes: dateAttributes)
            dateText.draw(in: CGRect(x: pageRect.width - 60 - dateSize.width, y: yPosition, width: dateSize.width, height: 18), withAttributes: dateAttributes)

            // MARK: - Executive Summary Box
            yPosition += 45
            yPosition = drawExecutiveSummaryBox(
                user: user,
                taxYear: taxYear,
                documentCount: documentCount,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // MARK: - Category Breakdown Table
            yPosition += 30
            yPosition = drawCategoryBreakdownTable(
                categoryBreakdown: categoryBreakdown,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // MARK: - Professional Footer
            drawProfessionalFooter(pageRect: pageRect, context: context.cgContext)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("title_page_\(taxYear).pdf")
        try pdfData.write(to: tempURL)

        print("✅ Professional title page created")
        return tempURL
    }

    /// Draw executive summary box with client information
    private func drawExecutiveSummaryBox(
        user: User,
        taxYear: Int,
        documentCount: Int,
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        let boxX: CGFloat = 60
        let boxWidth = pageRect.width - 120
        let boxHeight: CGFloat = 160
        let y = startY

        // Draw box with Swiss red accent border
        context.setFillColor(UIColor.white.cgColor)
        let boxRect = CGRect(x: boxX, y: y, width: boxWidth, height: boxHeight)
        context.fill(boxRect)

        context.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.setLineWidth(3.0)
        context.stroke(boxRect)

        // Box header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        ]
        "MANDANT / CLIENT".draw(in: CGRect(x: boxX + 20, y: y + 15, width: boxWidth - 40, height: 20), withAttributes: headerAttributes)

        // Client name(s)
        var contentY = y + 42
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        // Person 1 & Person 2 (joint filing)
        let person1Name = user.person1Name ?? user.name
        if let person2Name = user.person2Name, !person2Name.isEmpty {
            "\(person1Name) & \(person2Name)".draw(in: CGRect(x: boxX + 20, y: contentY, width: boxWidth - 40, height: 18), withAttributes: nameAttributes)
        } else {
            person1Name.draw(in: CGRect(x: boxX + 20, y: contentY, width: boxWidth - 40, height: 18), withAttributes: nameAttributes)
        }

        contentY += 24
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        // Details in two columns
        let leftColX = boxX + 20
        let rightColX = boxX + boxWidth / 2 + 10

        // Left column
        "AHV: \(user.person1AhvNumber ?? user.ahvNumber ?? "N/A")".draw(in: CGRect(x: leftColX, y: contentY, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)
        "Kanton: \(user.canton ?? "N/A")".draw(in: CGRect(x: leftColX, y: contentY + 20, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)
        "Gemeinde: \(user.municipality ?? "N/A")".draw(in: CGRect(x: leftColX, y: contentY + 40, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)

        // Right column
        "Steuerjahr: \(taxYear)".draw(in: CGRect(x: rightColX, y: contentY, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)
        "Anzahl Belege: \(documentCount)".draw(in: CGRect(x: rightColX, y: contentY + 20, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)
        "Status: ✓ Bereit zur Einreichung".draw(in: CGRect(x: rightColX, y: contentY + 40, width: boxWidth / 2 - 30, height: 16), withAttributes: detailAttributes)

        return y + boxHeight
    }

    /// Draw professional category breakdown table
    private func drawCategoryBreakdownTable(
        categoryBreakdown: [(category: String, count: Int, amount: Double?)],
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var y = startY

        // Table header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        "DOKUMENTEN-ÜBERSICHT".draw(in: CGRect(x: 60, y: y, width: pageRect.width - 120, height: 20), withAttributes: headerAttributes)
        y += 28

        // Table setup
        let tableX: CGFloat = 60
        let tableWidth = pageRect.width - 120
        let colWidths: [CGFloat] = [tableWidth * 0.60, tableWidth * 0.20, tableWidth * 0.20]
        let rowHeight: CGFloat = 28

        // Table header row
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 0.1)
        context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        context.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.setLineWidth(1.5)
        context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        "KATEGORIE".draw(in: CGRect(x: tableX + 10, y: y + 7, width: colWidths[0] - 20, height: 16), withAttributes: tableHeaderAttributes)
        "ANZAHL".draw(in: CGRect(x: tableX + colWidths[0] + 10, y: y + 7, width: colWidths[1] - 20, height: 16), withAttributes: tableHeaderAttributes)
        "STATUS".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 10, y: y + 7, width: colWidths[2] - 20, height: 16), withAttributes: tableHeaderAttributes)

        y += rowHeight

        // Table rows
        let rowTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]

        for (index, item) in categoryBreakdown.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
                context.setFillColor(UIColor(white: 0.97, alpha: 1.0).cgColor)
                context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))
            }

            // Row border
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

            // Content
            item.category.draw(in: CGRect(x: tableX + 10, y: y + 7, width: colWidths[0] - 20, height: 16), withAttributes: rowTextAttributes)
            "\(item.count)".draw(in: CGRect(x: tableX + colWidths[0] + 10, y: y + 7, width: colWidths[1] - 20, height: 16), withAttributes: countAttributes)
            "✓".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 10, y: y + 7, width: colWidths[2] - 20, height: 16), withAttributes: tableHeaderAttributes)

            y += rowHeight
        }

        // Total row
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 0.1)
        context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        context.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.setLineWidth(1.5)
        context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        "TOTAL".draw(in: CGRect(x: tableX + 10, y: y + 7, width: colWidths[0] - 20, height: 16), withAttributes: totalAttributes)
        let totalCount = categoryBreakdown.reduce(0) { $0 + $1.count }
        "\(totalCount)".draw(in: CGRect(x: tableX + colWidths[0] + 10, y: y + 7, width: colWidths[1] - 20, height: 16), withAttributes: totalAttributes)
        "✓".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 10, y: y + 7, width: colWidths[2] - 20, height: 16), withAttributes: totalAttributes)

        y += rowHeight

        return y
    }

    /// Draw professional footer with confidentiality notice
    private func drawProfessionalFooter(pageRect: CGRect, context: CGContext) {
        let footerY = pageRect.height - 100

        // Divider line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 60, y: footerY))
        context.addLine(to: CGPoint(x: pageRect.width - 60, y: footerY))
        context.strokePath()

        // Confidentiality notice
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .justified

        let disclaimerAttributesWithStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        let disclaimer = "Vertraulich: Dieses Dokument enthält vertrauliche Informationen und ist ausschliesslich für den bezeichneten Empfänger bestimmt. Eine unbefugte Weitergabe, Vervielfältigung oder Verwendung ist untersagt."
        disclaimer.draw(in: CGRect(x: 60, y: footerY + 10, width: pageRect.width - 120, height: 30), withAttributes: disclaimerAttributesWithStyle)

        // Company info
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        "TAXED GmbH | Biel/Bienne, Schweiz".draw(in: CGRect(x: 60, y: footerY + 45, width: pageRect.width - 120, height: 14), withAttributes: companyAttributes)

        let contactAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        "www.taxed.ch | support@taxed.ch".draw(in: CGRect(x: 60, y: footerY + 60, width: pageRect.width - 120, height: 12), withAttributes: contactAttributes)

        // Page number
        let pageNumAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let pageNumText = "Seite 1"
        let pageNumSize = pageNumText.size(withAttributes: pageNumAttributes)
        pageNumText.draw(in: CGRect(x: pageRect.width - 60 - pageNumSize.width, y: footerY + 60, width: pageNumSize.width, height: 12), withAttributes: pageNumAttributes)
    }

    /// Generate professional Swiss business format cover letter with category breakdown
    private func generateCoverLetter(
        user: User,
        taxYear: Int,
        documentCount: Int,
        categoryBreakdown: [(category: String, count: Int, amount: Double?)]
    ) async throws -> URL {
        print("📄 Generating professional cover letter")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 60

            // MARK: - Professional Letterhead
            // Logo
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            ]
            "TAXED.CH".draw(in: CGRect(x: 60, y: yPosition, width: 200, height: 28), withAttributes: logoAttributes)

            // Company address (right-aligned)
            let companyAddressAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .right
                    return style
                }()
            ]

            let companyAddress = """
            TAXED GmbH
            Biel/Bienne
            Schweiz
            Tel: +41 32 XXX XX XX
            www.taxed.ch
            """
            companyAddress.draw(in: CGRect(x: pageRect.width - 200, y: yPosition, width: 140, height: 70), withAttributes: companyAddressAttributes)

            // MARK: - Reference Numbers (Swiss Business Letter Standard)
            yPosition = 150

            let refAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            let userIdShort = String((user.id ?? "XXXXXX").prefix(6)).uppercased()
            let ourRef = "Unser Zeichen: TAX-\(taxYear)-\(userIdShort)"
            ourRef.draw(in: CGRect(x: 60, y: yPosition, width: 250, height: 14), withAttributes: refAttributes)

            let cantonRef = "Ihr Zeichen: \(user.canton ?? "CH")-\(user.municipality ?? "XXX")"
            cantonRef.draw(in: CGRect(x: pageRect.width - 250, y: yPosition, width: 190, height: 14), withAttributes: refAttributes)

            yPosition += 18
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "de_CH")
            dateFormatter.dateStyle = .long
            let dateStr = "Datum: \(dateFormatter.string(from: Date()))"
            dateStr.draw(in: CGRect(x: pageRect.width - 250, y: yPosition, width: 190, height: 14), withAttributes: refAttributes)

            // MARK: - Recipient Address (Swiss Window Position)
            yPosition += 35

            let recipientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black
            ]

            let person1Name = user.person1Name ?? user.name
            var recipientLines = [person1Name]

            if let person2Name = user.person2Name, !person2Name.isEmpty {
                recipientLines.append("& \(person2Name)")
            }

            if let street = user.street {
                recipientLines.append(street)
            }

            if let postalCode = user.postalCode, let city = user.city {
                recipientLines.append("\(postalCode) \(city)")
            }

            let recipientText = recipientLines.joined(separator: "\n")
            recipientText.draw(in: CGRect(x: 60, y: yPosition, width: 300, height: 80), withAttributes: recipientAttributes)

            // MARK: - Subject Line
            yPosition += 100

            let subjectAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Steuererklärung \(taxYear) – Dokumentenübermittlung".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 20), withAttributes: subjectAttributes)

            // MARK: - Letter Body
            yPosition += 35

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 4
                    return style
                }()
            ]

            let openingText = """
            Sehr geehrte Damen und Herren,

            Hiermit übermitteln wir Ihnen die vollständige Dokumentation zur Steuererklärung für das Steuerjahr \(taxYear). Das Dossier wurde professionell aufbereitet und enthält \(documentCount) Belege.
            """

            openingText.draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 70), withAttributes: bodyAttributes)

            // MARK: - Category Breakdown Table
            yPosition += 80
            yPosition = drawCoverLetterTable(
                categoryBreakdown: categoryBreakdown,
                startY: yPosition,
                pageRect: pageRect,
                context: context.cgContext
            )

            // MARK: - Key Points Section
            yPosition += 20

            let keyPointsHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Wichtige Hinweise:".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 18), withAttributes: keyPointsHeaderAttributes)

            yPosition += 24

            let bulletAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            let keyPoints = [
                "✓ Alle Dokumente sind mit professionellen Deckblättern versehen",
                "✓ Steuerindizes (Ziffer) gemäss kantonalen Anforderungen zugewiesen",
                "✓ QR-Codes für digitale Verifikation integriert",
                "✓ Kategorisierung nach Einkommen, Abzügen, Vermögen und Schulden"
            ]

            for point in keyPoints {
                point.draw(in: CGRect(x: 70, y: yPosition, width: pageRect.width - 130, height: 16), withAttributes: bulletAttributes)
                yPosition += 20
            }

            // MARK: - Closing
            yPosition += 20

            let closingText = """
            Die Unterlagen wurden sorgfältig geprüft und kategorisiert. Für Rückfragen stehen wir Ihnen jederzeit gerne zur Verfügung.

            Mit freundlichen Grüssen
            """

            closingText.draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 50), withAttributes: bodyAttributes)

            yPosition += 60

            let signatureAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
            ]
            "TAXED GmbH".draw(in: CGRect(x: 60, y: yPosition, width: 200, height: 18), withAttributes: signatureAttributes)

            yPosition += 20
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            "Ihr digitaler Steuerassistent".draw(in: CGRect(x: 60, y: yPosition, width: 200, height: 14), withAttributes: subtitleAttributes)

            // MARK: - Enclosures List
            yPosition += 35

            let enclosureHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Beilagen:".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 14), withAttributes: enclosureHeaderAttributes)

            yPosition += 18
            let enclosureAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            "• Steuerdokumente mit Deckblättern (\(documentCount) Belege)\n• Dokumentenverzeichnis nach Kategorien".draw(in: CGRect(x: 60, y: yPosition, width: pageRect.width - 120, height: 30), withAttributes: enclosureAttributes)

            // MARK: - Professional Footer
            let footerY = pageRect.height - 60
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: 60, y: footerY))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 60, y: footerY))
            context.cgContext.strokePath()

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            "TAXED GmbH | Biel/Bienne, Schweiz | www.taxed.ch | support@taxed.ch | Generiert: \(formatDate(Date()))".draw(in: CGRect(x: 60, y: footerY + 8, width: pageRect.width - 120, height: 12), withAttributes: footerAttributes)

            // Page number
            "Seite 1".draw(in: CGRect(x: pageRect.width - 90, y: footerY + 8, width: 30, height: 12), withAttributes: footerAttributes)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cover_letter_\(taxYear).pdf")
        try pdfData.write(to: tempURL)

        print("✅ Professional cover letter created")
        return tempURL
    }

    /// Draw category breakdown table in cover letter
    private func drawCoverLetterTable(
        categoryBreakdown: [(category: String, count: Int, amount: Double?)],
        startY: CGFloat,
        pageRect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var y = startY

        // Table header text
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        "Dokumentenaufstellung:".draw(in: CGRect(x: 60, y: y, width: pageRect.width - 120, height: 16), withAttributes: tableHeaderAttributes)
        y += 20

        // Table setup
        let tableX: CGFloat = 60
        let tableWidth: CGFloat = 380
        let colWidths: [CGFloat] = [tableWidth * 0.65, tableWidth * 0.18, tableWidth * 0.17]
        let rowHeight: CGFloat = 24

        // Table header row
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 0.1)
        context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        context.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.setLineWidth(1.0)
        context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        let headerTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        "KATEGORIE".draw(in: CGRect(x: tableX + 8, y: y + 6, width: colWidths[0] - 16, height: 14), withAttributes: headerTextAttributes)
        "ANZAHL".draw(in: CGRect(x: tableX + colWidths[0] + 8, y: y + 6, width: colWidths[1] - 16, height: 14), withAttributes: headerTextAttributes)
        "STATUS".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 8, y: y + 6, width: colWidths[2] - 16, height: 14), withAttributes: headerTextAttributes)

        y += rowHeight

        // Table rows
        let rowTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        let countTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]

        for (index, item) in categoryBreakdown.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
                context.setFillColor(UIColor(white: 0.97, alpha: 1.0).cgColor)
                context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))
            }

            // Row border
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.3)
            context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

            // Content
            item.category.draw(in: CGRect(x: tableX + 8, y: y + 6, width: colWidths[0] - 16, height: 14), withAttributes: rowTextAttributes)
            "\(item.count)".draw(in: CGRect(x: tableX + colWidths[0] + 8, y: y + 6, width: colWidths[1] - 16, height: 14), withAttributes: countTextAttributes)
            "✓".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 8, y: y + 6, width: colWidths[2] - 16, height: 14), withAttributes: headerTextAttributes)

            y += rowHeight
        }

        // Total row
        context.setFillColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 0.1)
        context.fill(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        context.setStrokeColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0)
        context.setLineWidth(1.0)
        context.stroke(CGRect(x: tableX, y: y, width: tableWidth, height: rowHeight))

        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        "TOTAL".draw(in: CGRect(x: tableX + 8, y: y + 6, width: colWidths[0] - 16, height: 14), withAttributes: totalAttributes)
        let totalCount = categoryBreakdown.reduce(0) { $0 + $1.count }
        "\(totalCount)".draw(in: CGRect(x: tableX + colWidths[0] + 8, y: y + 6, width: colWidths[1] - 16, height: 14), withAttributes: totalAttributes)
        "✓".draw(in: CGRect(x: tableX + colWidths[0] + colWidths[1] + 8, y: y + 6, width: colWidths[2] - 16, height: 14), withAttributes: totalAttributes)

        y += rowHeight

        return y
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

    // MARK: - QR Code & Barcode Generation

    /// Generate QR code with document metadata for Swiss tax office submission
    private func generateQRCode(
        document: TaxDocument,
        user: User,
        taxIndex: TaxIndexMapping?
    ) -> UIImage? {
        // Create JSON metadata for QR code
        var metadata: [String: String] = [
            "documentId": document.id,
            "documentName": document.name,
            "category": document.taxCategoryType ?? document.category.rawValue,
            "taxYear": String(document.taxYear),
            "uploadedAt": ISO8601DateFormatter().string(from: document.uploadedAt)
        ]

        if let canton = user.canton {
            metadata["canton"] = canton
        }

        if let index = taxIndex {
            metadata["taxIndex"] = "\(user.canton ?? "")-\(index.index)"
        }

        if let attachmentNumber = document.attachmentNumber {
            metadata["attachmentNumber"] = attachmentNumber
        }

        // Convert metadata to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to create QR code metadata")
            return nil
        }

        // Generate QR code using Core Image
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        filter.correctionLevel = "M" // Medium error correction

        guard let outputImage = filter.outputImage else {
            print("❌ Failed to generate QR code")
            return nil
        }

        // Scale up for better quality
        let scale = 10.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generate Code 128 barcode for document tracking
    private func generateBarcode(documentId: String) -> UIImage? {
        // Use document ID for barcode
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(documentId.utf8)

        guard let outputImage = filter.outputImage else {
            print("❌ Failed to generate barcode")
            return nil
        }

        // Scale for better quality
        let scaleX = 3.0
        let scaleY = 2.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Draw QR code or barcode on PDF
    private func drawCode(
        image: UIImage,
        x: CGFloat,
        y: CGFloat,
        size: CGFloat,
        context: CGContext
    ) {
        let rect = CGRect(x: x, y: y, width: size, height: size)
        context.saveGState()
        context.translateBy(x: 0, y: rect.origin.y + rect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(x: rect.origin.x, y: 0, width: rect.size.width, height: rect.size.height))
        }
        context.restoreGState()
    }

    /// Draw barcode with custom size
    private func drawCode(
        image: UIImage,
        x: CGFloat,
        y: CGFloat,
        size: CGSize,
        context: CGContext
    ) {
        let rect = CGRect(x: x, y: y, width: size.width, height: size.height)
        context.saveGState()
        context.translateBy(x: 0, y: rect.origin.y + rect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(x: rect.origin.x, y: 0, width: rect.size.width, height: rect.size.height))
        }
        context.restoreGState()
    }
}
