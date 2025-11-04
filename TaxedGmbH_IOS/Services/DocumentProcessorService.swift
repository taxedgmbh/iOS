//
//  DocumentProcessorService.swift
//  TaxedGmbH_IOS
//
//  AI-powered document OCR and categorization for Swiss tax documents
//

import Foundation
import Vision
import UIKit
import Combine

// MARK: - Document Category (Detailed AI Classification)

enum DocumentCategory: String, Codable, CaseIterable {
    case lohnausweis = "lohnausweis"
    case spesenbeleg = "spesenbeleg"
    case bankStatement = "bank_statement"
    case vermietung = "vermietung"
    case krankenArztkosten = "krankheit_arzt"
    case versicherung = "versicherung"
    case hypothekarzinsen = "hypothek"
    case spenden = "spenden"
    case kinderbetreuung = "kinderbetreuung"
    case weiterbildung = "weiterbildung"
    case pensionskasse = "pensionskasse"
    case steuerrechnung = "steuerrechnung"
    case other = "other"

    var displayName: String {
        switch self {
        case .lohnausweis: return "Lohnausweis"
        case .spesenbeleg: return "Spesenbeleg"
        case .bankStatement: return "Kontoauszug"
        case .vermietung: return "Vermietung"
        case .krankenArztkosten: return "Krankheits-/Arztkosten"
        case .versicherung: return "Versicherung"
        case .hypothekarzinsen: return "Hypothekarzinsen"
        case .spenden: return "Spenden"
        case .kinderbetreuung: return "Kinderbetreuung"
        case .weiterbildung: return "Weiterbildung"
        case .pensionskasse: return "Pensionskasse"
        case .steuerrechnung: return "Steuerrechnung"
        case .other: return "Sonstiges"
        }
    }

    // Map detailed category to high-level TaxCategory
    var taxCategory: TaxCategory {
        switch self {
        case .lohnausweis:
            return .income
        case .spesenbeleg, .krankenArztkosten, .versicherung, .hypothekarzinsen, .spenden, .kinderbetreuung, .weiterbildung:
            return .deduction
        case .pensionskasse:
            return .pillar
        case .bankStatement, .vermietung:
            return .wealth
        case .steuerrechnung, .other:
            return .uncategorized
        }
    }
}

// MARK: - Document Processing Errors

enum DocumentProcessingError: LocalizedError {
    case imageConversionFailed
    case ocrFailed
    case categorizationFailed
    case noTextDetected
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "documents.processing.error.image_conversion".localized
        case .ocrFailed:
            return "documents.processing.error.ocr_failed".localized
        case .categorizationFailed:
            return "documents.processing.error.categorization_failed".localized
        case .noTextDetected:
            return "documents.processing.error.no_text".localized
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Document Processing Result

struct DocumentProcessingResult {
    let extractedText: String
    let suggestedCategory: DocumentCategory
    let confidence: Double // 0.0 to 1.0
    let detectedKeywords: [String]
    let additionalInfo: [String: String]
}

// MARK: - Document Processor Service

@MainActor
class DocumentProcessorService: ObservableObject {
    static let shared = DocumentProcessorService()

    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0

    private init() {}

    // MARK: - Main Processing Pipeline

    /// Process document image: OCR + Categorization
    func processDocument(image: UIImage) async throws -> DocumentProcessingResult {
        isProcessing = true
        processingProgress = 0.0

        defer {
            isProcessing = false
            processingProgress = 0.0
        }

        // Step 1: Extract text using Vision OCR (40% progress)
        processingProgress = 0.1
        let extractedText = try await extractText(from: image)
        processingProgress = 0.4

        guard !extractedText.isEmpty else {
            throw DocumentProcessingError.noTextDetected
        }

        // Step 2: Categorize document based on extracted text (80% progress)
        processingProgress = 0.5
        let categoryResult = categorizeDocument(text: extractedText)
        processingProgress = 0.8

        // Step 3: Extract additional metadata
        let keywords = extractKeywords(from: extractedText)
        let additionalInfo = extractMetadata(from: extractedText, category: categoryResult.category)
        processingProgress = 1.0

        return DocumentProcessingResult(
            extractedText: extractedText,
            suggestedCategory: categoryResult.category,
            confidence: categoryResult.confidence,
            detectedKeywords: keywords,
            additionalInfo: additionalInfo
        )
    }

    // MARK: - OCR Text Extraction

    /// Extract text from image using Vision framework
    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw DocumentProcessingError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: DocumentProcessingError.ocrFailed)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentProcessingError.noTextDetected)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "fr-FR", "it-IT", "en-US"] // Swiss languages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DocumentProcessingError.ocrFailed)
            }
        }
    }

    // MARK: - Document Categorization

    /// Categorize document based on extracted text using keyword matching
    private func categorizeDocument(text: String) -> (category: DocumentCategory, confidence: Double) {
        let lowercasedText = text.lowercased()

        // Define keywords for each Swiss tax document category
        let categoryKeywords: [(DocumentCategory, [String], Double)] = [
            // Lohnausweis (Salary statement) - highest priority
            (.lohnausweis, [
                "lohnausweis", "salary certificate", "certificat de salaire",
                "ahv", "alv", "pensionskasse", "bvg", "salär", "bruttolohn",
                "nettolohn", "quellensteuer", "arbeitgeber"
            ], 0.9),

            // Spesenbelege (Expense receipts)
            (.spesenbeleg, [
                "quittung", "receipt", "reçu", "ricevuta",
                "rechnung", "invoice", "facture", "fattura",
                "spesen", "expenses", "frais", "total chf"
            ], 0.85),

            // Bank statements
            (.bankStatement, [
                "kontoauszug", "bank statement", "relevé bancaire",
                "iban", "saldo", "gutschrift", "belastung",
                "überweisung", "postfinance", "ubs", "credit suisse", "raiffeisen"
            ], 0.85),

            // Vermietung (Rental income)
            (.vermietung, [
                "mietvertrag", "rental agreement", "contrat de bail",
                "miete", "rent", "loyer", "affitto",
                "liegenschaft", "immobilie", "vermieter"
            ], 0.85),

            // Medical expenses
            (.krankenArztkosten, [
                "arztrechnung", "medical bill", "facture médicale",
                "krankenhaus", "hospital", "hôpital",
                "medikament", "medication", "médicament",
                "krankenkasse", "health insurance", "franchise", "selbstbehalt"
            ], 0.85),

            // Insurance
            (.versicherung, [
                "versicherung", "insurance", "assurance",
                "police", "prämie", "premium", "prime",
                "haftpflicht", "hausrat", "lebensversicherung"
            ], 0.8),

            // Mortgage interest
            (.hypothekarzinsen, [
                "hypothek", "mortgage", "hypothèque",
                "zins", "interest", "intérêt",
                "darlehen", "loan", "prêt", "amortisation"
            ], 0.85),

            // Donations
            (.spenden, [
                "spende", "donation", "don",
                "spendenquittung", "wohltätig", "charity",
                "gemeinnützig", "non-profit"
            ], 0.9),

            // Childcare
            (.kinderbetreuung, [
                "kita", "kindertagesstätte", "daycare", "crèche",
                "kinderbetreuung", "childcare", "garde d'enfants",
                "tagesmutter", "babysitter"
            ], 0.9),

            // Education
            (.weiterbildung, [
                "weiterbildung", "kurs", "course", "cours",
                "ausbildung", "training", "formation",
                "seminar", "workshop", "zertifikat"
            ], 0.8),

            // Pension statements
            (.pensionskasse, [
                "pensionskasse", "pension fund", "caisse de pension",
                "vorsorge", "säule 3a", "säule 2",
                "bvg", "freizügigkeit"
            ], 0.9),

            // Tax assessment
            (.steuerrechnung, [
                "steuerrechnung", "tax bill", "facture d'impôt",
                "steuerverwaltung", "tax office", "fisc",
                "veranlagung", "einkommenssteuer", "vermögenssteuer"
            ], 0.9)
        ]

        var bestMatch: (DocumentCategory, Double) = (.other, 0.0)

        for (category, keywords, baseConfidence) in categoryKeywords {
            var matchCount = 0
            let totalKeywords = keywords.count

            for keyword in keywords {
                if lowercasedText.contains(keyword) {
                    matchCount += 1
                }
            }

            if matchCount > 0 {
                // Calculate confidence based on match ratio
                let matchRatio = Double(matchCount) / Double(totalKeywords)
                let confidence = min(baseConfidence * (0.5 + matchRatio), 1.0)

                if confidence > bestMatch.1 {
                    bestMatch = (category, confidence)
                }
            }
        }

        // If no category matched well, return .other with low confidence
        if bestMatch.1 < 0.3 {
            return (.other, bestMatch.1)
        }

        return bestMatch
    }

    // MARK: - Metadata Extraction

    /// Extract keywords from text for search/filtering
    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let meaningfulWords = words.filter { word in
            word.count > 3 && !word.isEmpty
        }

        // Return first 10 unique keywords
        return Array(Set(meaningfulWords.map { $0.lowercased() })).prefix(10).map { $0 }
    }

    /// Extract specific metadata based on document category
    private func extractMetadata(from text: String, category: DocumentCategory) -> [String: String] {
        var metadata: [String: String] = [:]

        // Extract dates (Swiss format: DD.MM.YYYY)
        if let date = extractDate(from: text) {
            metadata["date"] = date
        }

        // Extract amounts (CHF)
        if let amount = extractAmount(from: text) {
            metadata["amount"] = amount
        }

        // Category-specific extraction
        switch category {
        case .lohnausweis:
            // Extract employer name (heuristic: look for "Arbeitgeber" keyword)
            if let employer = extractEmployer(from: text) {
                metadata["employer"] = employer
            }

        case .spesenbeleg, .krankenArztkosten:
            // Extract vendor/provider name (heuristic: first line usually)
            if let vendor = extractVendor(from: text) {
                metadata["vendor"] = vendor
            }

        case .bankStatement:
            // Extract IBAN
            if let iban = extractIBAN(from: text) {
                metadata["iban"] = iban
            }

        default:
            break
        }

        return metadata
    }

    // MARK: - Helper Extraction Methods

    private func extractDate(from text: String) -> String? {
        // Match Swiss date format: DD.MM.YYYY
        let pattern = "\\b(0[1-9]|[12][0-9]|3[01])\\.(0[1-9]|1[0-2])\\.(20\\d{2})\\b"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private func extractAmount(from text: String) -> String? {
        // Match CHF amounts: CHF 1'234.56 or 1'234.56 CHF
        let pattern = "(CHF\\s*)?([0-9]{1,3}(?:'[0-9]{3})*(?:\\.[0-9]{2})?)(\\s*CHF)?"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private func extractEmployer(from text: String) -> String? {
        // Look for line after "Arbeitgeber" keyword
        let lines = text.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains("arbeitgeber") && index + 1 < lines.count {
                let nextLine = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !nextLine.isEmpty && nextLine.count > 3 {
                    return nextLine
                }
            }
        }
        return nil
    }

    private func extractVendor(from text: String) -> String? {
        // Heuristic: first non-empty line is often the vendor name
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.count > 3 && trimmed.count < 100 {
                return trimmed
            }
        }
        return nil
    }

    private func extractIBAN(from text: String) -> String? {
        // Match Swiss IBAN: CH## #### #### #### #### #
        let pattern = "CH\\d{2}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range]).replacingOccurrences(of: " ", with: "")
        }
        return nil
    }
}
