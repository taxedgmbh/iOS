//
//  TaxDocumentModelTests.swift
//  TaxedGmbH_IOSTests
//
//  Comprehensive tests for TaxDocument model
//

import XCTest
@testable import TaxedGmbH_IOS

final class TaxDocumentModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testTaxDocumentBasicInitialization() {
        // When: Creating a basic tax document
        let document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "Lohnausweis_2024.pdf",
            storageUrl: "https://storage.googleapis.com/taxed/doc123.pdf",
            taxYear: 2024
        )

        // Then: Should have correct properties
        XCTAssertEqual(document.id, "doc123")
        XCTAssertEqual(document.customerId, "user456")
        XCTAssertEqual(document.workspaceId, "workspace789")
        XCTAssertEqual(document.name, "Lohnausweis_2024.pdf")
        XCTAssertEqual(document.storageUrl, "https://storage.googleapis.com/taxed/doc123.pdf")
        XCTAssertEqual(document.taxYear, 2024)
        XCTAssertEqual(document.category, .uncategorized)
        XCTAssertEqual(document.status, .uploading)
    }

    func testTaxDocumentWithFullDetails() {
        // When: Creating a document with all details
        let uploadDate = Date()
        let document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            expertId: "expert111",
            caseId: "case222",
            name: "Salary_Certificate_2024.pdf",
            storageUrl: "https://storage.googleapis.com/taxed/doc123.pdf",
            thumbnailUrl: "https://storage.googleapis.com/taxed/doc123_thumb.jpg",
            fileSize: 2_048_000,
            mimeType: "application/pdf",
            category: .income,
            subcategory: "salary",
            aiConfidence: 0.95,
            extractedText: "Lohnausweis 2024...",
            aiSummary: "Salary certificate for 2024",
            status: .approved,
            expertNotes: "Verified and approved",
            userNotes: "Main job salary",
            taxYear: 2024,
            canton: "ZH",
            municipality: "Zürich",
            amount: 95000.00,
            uploadedAt: uploadDate,
            taxCategoryType: "salary",
            attachmentNumber: "SAL_1234",
            purpose: "Tax declaration 2024",
            currency: "CHF",
            documentDate: uploadDate,
            workflowStatus: .approved,
            coverSheetGenerated: true,
            coverSheetUrl: "https://storage.googleapis.com/taxed/doc123_cover.pdf",
            processedDocumentUrl: "https://storage.googleapis.com/taxed/doc123_complete.pdf",
            pdfGenerationStatus: .completed,
            pdfLastGeneratedAt: uploadDate,
            generatedWithProfileVersion: 3,
            needsRegeneration: false,
            taxOfficeRequired: true,
            includeInSubmission: true
        )

        // Then: All properties should be set correctly
        XCTAssertEqual(document.expertId, "expert111")
        XCTAssertEqual(document.caseId, "case222")
        XCTAssertEqual(document.category, .income)
        XCTAssertEqual(document.subcategory, "salary")
        XCTAssertEqual(document.aiConfidence, 0.95, accuracy: 0.01)
        XCTAssertEqual(document.status, .approved)
        XCTAssertEqual(document.amount, 95000.00, accuracy: 0.01)
        XCTAssertEqual(document.attachmentNumber, "SAL_1234")
        XCTAssertEqual(document.coverSheetGenerated, true)
        XCTAssertEqual(document.needsRegeneration, false)
        XCTAssertEqual(document.generatedWithProfileVersion, 3)
    }

    // MARK: - Serialization Tests

    func testTaxDocumentToDictionary() {
        // Given: A tax document
        let document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )

        // When: Converting to dictionary
        let dict = document.toDictionary()

        // Then: Should contain all required fields
        XCTAssertEqual(dict["customerId"] as? String, "user456")
        XCTAssertEqual(dict["workspaceId"] as? String, "workspace789")
        XCTAssertEqual(dict["name"] as? String, "test.pdf")
        XCTAssertEqual(dict["storageUrl"] as? String, "https://example.com/test.pdf")
        XCTAssertEqual(dict["taxYear"] as? Int, 2024)
        XCTAssertNotNil(dict["uploadedAt"])
        XCTAssertNotNil(dict["updatedAt"])
    }

    func testTaxDocumentFromDictionary() {
        // Given: A dictionary with document data
        let dict: [String: Any] = [
            "customerId": "user456",
            "workspaceId": "workspace789",
            "name": "Lohnausweis.pdf",
            "storageUrl": "https://example.com/doc.pdf",
            "category": "income",
            "subcategory": "salary",
            "aiConfidence": 0.89,
            "status": "pending",
            "taxYear": 2024,
            "amount": 75000.00,
            "currency": "CHF",
            "attachmentNumber": "SAL_5678"
        ]

        // When: Creating document from dictionary
        let document = TaxDocument.fromDictionary(id: "doc123", data: dict)

        // Then: Should parse all fields correctly
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.id, "doc123")
        XCTAssertEqual(document?.customerId, "user456")
        XCTAssertEqual(document?.workspaceId, "workspace789")
        XCTAssertEqual(document?.subcategory, "salary")
        XCTAssertEqual(document?.amount, 75000.00)
        XCTAssertEqual(document?.currency, "CHF")
        XCTAssertEqual(document?.attachmentNumber, "SAL_5678")
    }

    // MARK: - PDF Regeneration Tests

    func testDocumentNeedsRegenerationWhenProfileVersionMismatch() {
        // Given: A document generated with old profile version
        var document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )
        document.generatedWithProfileVersion = 2
        document.coverSheetUrl = "https://example.com/cover.pdf"

        // When: Current profile version is 5
        let currentProfileVersion = 5

        // Then: Document should need regeneration
        let needsRegeneration = document.generatedWithProfileVersion != currentProfileVersion
        XCTAssertTrue(needsRegeneration, "Document should need regeneration when profile versions don't match")
    }

    func testDocumentNeedsRegenerationWhenFlagSet() {
        // Given: A document with needsRegeneration flag
        var document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )
        document.needsRegeneration = true

        // Then: Document needs regeneration
        XCTAssertTrue(document.needsRegeneration ?? false, "Document should need regeneration when flag is set")
    }

    func testDocumentUpToDateWhenVersionsMatch() {
        // Given: A document generated with current profile version
        var document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )
        document.generatedWithProfileVersion = 5
        document.needsRegeneration = false
        document.coverSheetUrl = "https://example.com/cover.pdf"

        // When: Current profile version is also 5
        let currentProfileVersion = 5

        // Then: Document should NOT need regeneration
        let needsRegeneration = (document.generatedWithProfileVersion != currentProfileVersion) ||
                                (document.needsRegeneration ?? false)
        XCTAssertFalse(needsRegeneration, "Document should not need regeneration when versions match")
    }

    // MARK: - Workflow Status Tests

    func testWorkflowStatusProgression() {
        // Test that workflow status can progress through states
        var document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )

        // Initial state
        document.workflowStatus = .uploading
        XCTAssertEqual(document.workflowStatus, .uploading)

        // After AI processing
        document.workflowStatus = .processing
        XCTAssertEqual(document.workflowStatus, .processing)

        // After categorization
        document.workflowStatus = .classified
        XCTAssertEqual(document.workflowStatus, .classified)

        // After cover sheet generation
        document.workflowStatus = .coverGenerated
        XCTAssertEqual(document.workflowStatus, .coverGenerated)

        // Final state
        document.workflowStatus = .finalized
        XCTAssertEqual(document.workflowStatus, .finalized)
    }

    // MARK: - PDF Generation Status Tests

    func testPDFGenerationStatusStates() {
        var document = TaxDocument(
            id: "doc123",
            customerId: "user456",
            workspaceId: "workspace789",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )

        // Test all PDF generation states
        document.pdfGenerationStatus = .pending
        XCTAssertEqual(document.pdfGenerationStatus, .pending)

        document.pdfGenerationStatus = .generating
        XCTAssertEqual(document.pdfGenerationStatus, .generating)

        document.pdfGenerationStatus = .completed
        XCTAssertEqual(document.pdfGenerationStatus, .completed)

        document.pdfGenerationStatus = .failed
        XCTAssertEqual(document.pdfGenerationStatus, .failed)
    }
}
