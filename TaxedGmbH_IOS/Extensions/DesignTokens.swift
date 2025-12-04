//
//  DesignTokens.swift
//  TaxedGmbH_IOS
//
//  Standardized design tokens for consistent UI across the app
//  Following Apple HIG guidelines for spacing and sizing
//

import SwiftUI

// MARK: - Spacing & Padding
extension CGFloat {
    /// Extra tight padding: 4pt (minimal spacing)
    static let paddingExtraTight: CGFloat = 4

    /// Tight padding: 8pt (compact elements)
    static let paddingTight: CGFloat = 8

    /// Standard padding: 12pt (default spacing)
    static let paddingStandard: CGFloat = 12

    /// Comfortable padding: 14pt (breathing room)
    static let paddingComfortable: CGFloat = 14

    /// Relaxed padding: 16pt (generous spacing)
    static let paddingRelaxed: CGFloat = 16

    /// Spacious padding: 20pt (section spacing)
    static let paddingSpacious: CGFloat = 20
}

// MARK: - Corner Radius
extension CGFloat {
    /// Small corner radius: 6pt (compact buttons, tags)
    static let cornerRadiusSmall: CGFloat = 6

    /// Medium corner radius: 8pt (standard buttons, cards)
    static let cornerRadiusMedium: CGFloat = 8

    /// Large corner radius: 12pt (large cards, containers)
    static let cornerRadiusLarge: CGFloat = 12

    /// Extra large corner radius: 16pt (prominent sections)
    static let cornerRadiusExtraLarge: CGFloat = 16
}

// MARK: - Vertical Spacing
extension CGFloat {
    /// Tight vertical spacing: 5pt
    static let verticalSpacingTight: CGFloat = 5

    /// Standard vertical spacing: 6pt
    static let verticalSpacingStandard: CGFloat = 6

    /// Comfortable vertical spacing: 8pt
    static let verticalSpacingComfortable: CGFloat = 8
}

// MARK: - Shadow
struct TaxedShadow {
    /// Light shadow for subtle elevation
    static let light = (color: Color.black.opacity(0.05), radius: 4.0, x: 0.0, y: 2.0)

    /// Medium shadow for cards and buttons
    static let medium = (color: Color.black.opacity(0.1), radius: 8.0, x: 0.0, y: 2.0)

    /// Strong shadow for prominent elements
    static let strong = (color: Color.black.opacity(0.15), radius: 12.0, x: 0.0, y: 4.0)
}

// MARK: - Icon Sizes
extension CGFloat {
    /// Small icon: 16pt
    static let iconSizeSmall: CGFloat = 16

    /// Medium icon: 20pt
    static let iconSizeMedium: CGFloat = 20

    /// Large icon: 24pt
    static let iconSizeLarge: CGFloat = 24

    /// Extra large icon: 32pt
    static let iconSizeExtraLarge: CGFloat = 32
}
