//
//  PDFAnnotationRect.swift
//  TaxedGmbH_IOS
//
//  PDF Annotation data model for drawing rectangles on PDFs
//  Stores normalized coordinates (0-1) for device independence
//

import Foundation
import UIKit
import FirebaseFirestore

/// Represents a rectangular annotation on a PDF page
struct PDFAnnotationRect: Codable, Identifiable, Equatable {
    let id: String
    let page: Int  // Zero-indexed PDF page number
    let rect: NormalizedRect  // Normalized coordinates (0-1 range)
    let color: String  // Hex color string
    let strokeWidth: Double
    let createdAt: Date
    var extractedText: String?  // Optional OCR result from annotated region

    init(id: String = UUID().uuidString,
         page: Int,
         rect: NormalizedRect,
         color: String = "#E71E24",  // Taxed red color
         strokeWidth: Double = 2.0,
         createdAt: Date = Date(),
         extractedText: String? = nil) {
        self.id = id
        self.page = page
        self.rect = rect
        self.color = color
        self.strokeWidth = strokeWidth
        self.createdAt = createdAt
        self.extractedText = extractedText
    }

    // Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "page": page,
            "rect": rect.toFirestore(),
            "color": color,
            "strokeWidth": strokeWidth,
            "createdAt": Timestamp(date: createdAt)
        ]
        if let text = extractedText {
            dict["extractedText"] = text
        }
        return dict
    }

    // Create from Firestore dictionary
    static func fromFirestore(_ data: [String: Any]) -> PDFAnnotationRect? {
        guard let id = data["id"] as? String,
              let page = data["page"] as? Int,
              let rectData = data["rect"] as? [String: Any],
              let rect = NormalizedRect.fromFirestore(rectData),
              let color = data["color"] as? String,
              let strokeWidth = data["strokeWidth"] as? Double,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        let extractedText = data["extractedText"] as? String

        return PDFAnnotationRect(
            id: id,
            page: page,
            rect: rect,
            color: color,
            strokeWidth: strokeWidth,
            createdAt: timestamp.dateValue(),
            extractedText: extractedText
        )
    }
}

/// Normalized rectangle with coordinates in 0-1 range for device independence
struct NormalizedRect: Codable, Equatable {
    let x: Double  // Top-left x (0 = left edge, 1 = right edge)
    let y: Double  // Top-left y (0 = top edge, 1 = bottom edge)
    let width: Double
    let height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x.clamped(to: 0...1)
        self.y = y.clamped(to: 0...1)
        self.width = width.clamped(to: 0...1)
        self.height = height.clamped(to: 0...1)
    }

    /// Create from CGRect and PDF page bounds
    init(from cgRect: CGRect, pageBounds: CGRect) {
        self.x = (cgRect.origin.x - pageBounds.origin.x) / pageBounds.width
        self.y = (cgRect.origin.y - pageBounds.origin.y) / pageBounds.height
        self.width = cgRect.width / pageBounds.width
        self.height = cgRect.height / pageBounds.height
    }

    /// Convert to CGRect given PDF page bounds
    func toCGRect(pageBounds: CGRect) -> CGRect {
        return CGRect(
            x: pageBounds.origin.x + (x * pageBounds.width),
            y: pageBounds.origin.y + (y * pageBounds.height),
            width: width * pageBounds.width,
            height: height * pageBounds.height
        )
    }

    // Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        return [
            "x": x,
            "y": y,
            "width": width,
            "height": height
        ]
    }

    // Create from Firestore dictionary
    static func fromFirestore(_ data: [String: Any]) -> NormalizedRect? {
        guard let x = data["x"] as? Double,
              let y = data["y"] as? Double,
              let width = data["width"] as? Double,
              let height = data["height"] as? Double else {
            return nil
        }
        return NormalizedRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Extensions

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension UIColor {
    /// Initialize from hex string
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Convert to hex string
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06X", rgb)
    }
}
