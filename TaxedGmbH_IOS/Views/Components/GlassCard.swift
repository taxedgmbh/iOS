//
//  GlassCard.swift
//  TaxedGmbH_IOS
//
//  Reusable glass-effect card component following Apple's design guidelines
//  Uses SwiftUI materials for depth, translucency, and vibrancy
//

import SwiftUI

/// Material thickness variants for glass effects
enum GlassMaterialThickness {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        }
    }
}

/// Glass card with customizable material thickness and tint
struct GlassCard<Content: View>: View {
    let content: Content
    let thickness: GlassMaterialThickness
    let cornerRadius: CGFloat
    let tintColor: Color?
    let strokeColor: Color?
    let strokeWidth: CGFloat

    init(
        thickness: GlassMaterialThickness = .regular,
        cornerRadius: CGFloat = 16,
        tintColor: Color? = nil,
        strokeColor: Color? = nil,
        strokeWidth: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.thickness = thickness
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        content
            .background {
                ZStack {
                    // Material background for glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(thickness.material)

                    // Optional tint overlay
                    if let tintColor = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tintColor.opacity(0.1))
                    }
                }
            }
            .overlay {
                // Optional stroke
                if let strokeColor = strokeColor, strokeWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(strokeColor.opacity(0.2), lineWidth: strokeWidth)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Glass background modifier for easy application
struct GlassBackgroundModifier: ViewModifier {
    let thickness: GlassMaterialThickness
    let cornerRadius: CGFloat
    let tintColor: Color?

    func body(content: Content) -> some View {
        content
            .background(thickness.material, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if let tintColor = tintColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tintColor.opacity(0.08))
                }
            }
    }
}

extension View {
    /// Apply glass background with material
    func glassBackground(
        thickness: GlassMaterialThickness = .regular,
        cornerRadius: CGFloat = 12,
        tintColor: Color? = nil
    ) -> some View {
        modifier(GlassBackgroundModifier(
            thickness: thickness,
            cornerRadius: cornerRadius,
            tintColor: tintColor
        ))
    }
}

/// Frosted glass overlay for layering effects
struct FrostedGlass: View {
    let thickness: GlassMaterialThickness
    let blur: CGFloat
    let opacity: Double

    init(
        thickness: GlassMaterialThickness = .thin,
        blur: CGFloat = 10,
        opacity: Double = 0.3
    ) {
        self.thickness = thickness
        self.blur = blur
        self.opacity = opacity
    }

    var body: some View {
        Rectangle()
            .fill(thickness.material)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Preview

#Preview("Glass Card Variants") {
    ZStack {
        // Background gradient to show glass effect
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                // Ultra Thin
                GlassCard(thickness: .ultraThin, tintColor: .blue) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ultra Thin Material")
                            .font(.headline)
                        Text("Most transparent, shows background clearly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Thin
                GlassCard(thickness: .thin, tintColor: .green) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thin Material")
                            .font(.headline)
                        Text("Subtle glass effect with light blur")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Regular
                GlassCard(thickness: .regular, tintColor: .orange, strokeColor: .orange, strokeWidth: 1) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Regular Material")
                            .font(.headline)
                        Text("Balanced glass effect - recommended default")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Thick
                GlassCard(thickness: .thick, tintColor: .purple) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thick Material")
                            .font(.headline)
                        Text("Strong glass effect with more opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Ultra Thick
                GlassCard(thickness: .ultraThick, tintColor: .red, strokeColor: .red, strokeWidth: 2) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ultra Thick Material")
                            .font(.headline)
                        Text("Most opaque, minimal background visibility")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}
