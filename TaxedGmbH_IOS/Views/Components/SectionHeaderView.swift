//
//  SectionHeaderView.swift
//  TaxedGmbH_IOS
//
//  Reusable section header component for consistent UI across the app
//  Following Apple HIG guidelines for section headers
//

import SwiftUI

// MARK: - Section Header View
/// Reusable section header component with icon and title
/// Use for section headers throughout the app
struct SectionHeaderView: View {
    let title: String
    let systemImage: String?
    let font: Font
    let foregroundColor: Color

    init(
        title: String,
        systemImage: String? = nil,
        font: Font = .headline,
        foregroundColor: Color = .primary
    ) {
        self.title = title
        self.systemImage = systemImage
        self.font = font
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        if let systemImage = systemImage {
            Label(title, systemImage: systemImage)
                .font(font)
                .foregroundColor(foregroundColor)
        } else {
            Text(title)
                .font(font)
                .foregroundColor(foregroundColor)
        }
    }
}

// MARK: - View Extension
extension View {
    /// Create a section with a standardized header
    func sectionHeader(title: String, systemImage: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: .paddingTight) {
            SectionHeaderView(title: title, systemImage: systemImage)
            self
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: .paddingRelaxed) {
        SectionHeaderView(title: "Documents", systemImage: "doc.fill")

        SectionHeaderView(title: "Settings", systemImage: "gear")
            .foregroundColor(.blue)

        SectionHeaderView(title: "Multiple PDFs", systemImage: "doc.on.doc.fill")

        SectionHeaderView(title: "Plain Header")
    }
    .padding()
}
