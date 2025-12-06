//
//  ButtonStyles.swift
//  TaxedGmbH_IOS
//
//  Reusable button styles for consistent UI across the app
//  Following Apple HIG guidelines for button design
//

import SwiftUI

// MARK: - Primary Button Style
/// Primary button style with comfortable padding and medium corner radius
/// Use for primary/call-to-action buttons
struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, .paddingComfortable)
            .padding(.vertical, .verticalSpacingComfortable)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(.cornerRadiusMedium)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
/// Secondary button style with standard padding and medium corner radius
/// Use for secondary actions and inline controls
struct SecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, .paddingStandard)
            .padding(.vertical, .verticalSpacingStandard)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(.cornerRadiusMedium)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Button Style
/// Compact button style with tight padding and small corner radius
/// Use for space-constrained areas and dense UI
struct CompactButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, .paddingTight + 2)
            .padding(.vertical, .verticalSpacingTight)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(.cornerRadiusSmall)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension View {
    /// Apply primary button style with specified background color
    func primaryButtonStyle(backgroundColor: Color, foregroundColor: Color = .white) -> some View {
        self.buttonStyle(PrimaryButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }

    /// Apply secondary button style with specified background color
    func secondaryButtonStyle(backgroundColor: Color, foregroundColor: Color = .white) -> some View {
        self.buttonStyle(SecondaryButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }

    /// Apply compact button style with specified background color
    func compactButtonStyle(backgroundColor: Color, foregroundColor: Color = .white) -> some View {
        self.buttonStyle(CompactButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}
