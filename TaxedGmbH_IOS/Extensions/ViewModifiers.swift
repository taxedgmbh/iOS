//
//  ViewModifiers.swift
//  TaxedGmbH_IOS
//
//  Reusable view modifiers for consistent UI patterns across the app
//  Following Apple HIG guidelines for visual hierarchy and feedback
//

import SwiftUI

// MARK: - Card Style Modifier
/// Applies a card-like appearance with background, corner radius, and shadow
struct CardModifier: ViewModifier {
    var backgroundColor: Color = Color(UIColor.systemBackground)
    var cornerRadius: CGFloat = .cornerRadiusLarge
    var shadowColor: Color = TaxedShadow.medium.color
    var shadowRadius: CGFloat = TaxedShadow.medium.radius
    var shadowX: CGFloat = TaxedShadow.medium.x
    var shadowY: CGFloat = TaxedShadow.medium.y

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowX,
                y: shadowY
            )
    }
}

// MARK: - Loading Overlay Modifier
/// Displays a loading overlay with progress indicator over the content
struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                VStack(spacing: .paddingStandard) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)

                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.paddingRelaxed)
                .background(
                    Color(UIColor.systemBackground)
                        .opacity(0.95)
                        .cornerRadius(.cornerRadiusMedium)
                )
                .shadow(
                    color: TaxedShadow.medium.color,
                    radius: TaxedShadow.medium.radius,
                    x: TaxedShadow.medium.x,
                    y: TaxedShadow.medium.y
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Error Banner Modifier
/// Displays an error banner at the top of the view
struct ErrorBannerModifier: ViewModifier {
    let errorMessage: String?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: .iconSizeSmall))

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: .iconSizeSmall))
                    }
                }
                .padding(.horizontal, .paddingStandard)
                .padding(.vertical, .paddingTight)
                .background(Color.red)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            content
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: errorMessage)
    }
}

// MARK: - Liquid Glass Card Modifier
/// Applies liquid glass design with glassmorphism effects
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var borderColor: Color = .white
    var glowColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.7),
                        Color.white.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 10)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderColor.opacity(0.6),
                                borderColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
            .if(glowColor != nil) { view in
                view.shadow(color: (glowColor ?? .clear).opacity(0.3), radius: 15, x: 0, y: 0)
            }
    }
}

// MARK: - Floating Button Modifier
/// Applies floating glass button style
struct FloatingButtonModifier: ViewModifier {
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Shimmer Effect Modifier
/// Adds shimmer animation effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 2.0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

// MARK: - Glow Effect Modifier
/// Adds glow effect around view
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Conditional Modifier Helper
extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply card style with optional customization
    func cardStyle(
        backgroundColor: Color = Color(UIColor.systemBackground),
        cornerRadius: CGFloat = .cornerRadiusLarge
    ) -> some View {
        self.modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply loading overlay with optional message
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }

    /// Apply error banner at the top
    func errorBanner(errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(ErrorBannerModifier(errorMessage: errorMessage, onDismiss: onDismiss))
    }

    /// Apply liquid glass card style
    func glassCard(
        cornerRadius: CGFloat = 24,
        borderColor: Color = .white,
        glowColor: Color? = nil
    ) -> some View {
        self.modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            glowColor: glowColor
        ))
    }

    /// Apply floating button style
    func floatingButton(isPressed: Bool = false) -> some View {
        self.modifier(FloatingButtonModifier(isPressed: isPressed))
    }

    /// Apply shimmer effect
    func shimmer(duration: Double = 2.0) -> some View {
        self.modifier(ShimmerModifier(duration: duration))
    }

    /// Apply glow effect
    func glow(color: Color, radius: CGFloat = 12) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: .paddingRelaxed) {
        Text("Card Example")
            .padding()
            .cardStyle()

        Text("Loading Example")
            .frame(maxWidth: .infinity)
            .padding()
            .cardStyle()
            .loadingOverlay(isLoading: true, message: "Loading...")

        VStack {
            Text("Content with Error Banner")
                .padding()
        }
        .errorBanner(errorMessage: "An error occurred", onDismiss: {})
    }
    .padding()
}
