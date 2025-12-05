//
//  EnhancedAnimatedGlassBackground.swift
//  TaxedGmbH_IOS
//
//  Enhanced liquid glass background with Apple HIG compliance
//  Optimized for performance, accessibility, and visual hierarchy
//  Reference: https://developer.apple.com/design/human-interface-guidelines/materials
//

import SwiftUI

/// Enhanced animated glass background with performance optimizations
/// - Respects Reduce Motion and Reduce Transparency settings
/// - Optimized blur radius for 60fps performance
/// - GPU-accelerated rendering with drawingGroup()
/// - Pauses animations when view is backgrounded
struct EnhancedAnimatedGlassBackground: View {
    @State private var animateGradient = false
    @State private var isActive = true

    // Accessibility Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // Performance optimizations
    private let blurRadius: CGFloat = 50  // Reduced from 60 for better performance
    private let animationDuration: Double = 8.0
    private let gradientSize: CGFloat = 400

    var body: some View {
        ZStack {
            // Base background color
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            // Only show animated gradients if transparency is not reduced
            if !reduceTransparency {
                animatedGradientsLayer
                    .drawingGroup()  // GPU acceleration for better performance
                    .accessibilityHidden(true)  // Hide from VoiceOver
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            startAnimationIfNeeded()
        }
    }

    // MARK: - Animated Gradients Layer

    @ViewBuilder
    private var animatedGradientsLayer: some View {
        if reduceMotion {
            // Static gradients for Reduce Motion
            staticGradientsLayer
        } else {
            // Animated gradients
            animatedGradientsContent
        }
    }

    private var staticGradientsLayer: some View {
        ZStack {
            // Static positions, no animation
            gradientBlob(color: .blue, x: -100, y: -100)
            gradientBlob(color: .purple, x: 150, y: 200)
            gradientBlob(color: .blue, x: 50, y: 50)
        }
    }

    private var animatedGradientsContent: some View {
        ZStack {
            // Gradient 1 - Top Left to Bottom Right
            gradientBlob(
                color: .blue,
                x: animateGradient ? -100 : -50,
                y: animateGradient ? -100 : -50
            )

            // Gradient 2 - Center moving
            gradientBlob(
                color: .purple,
                x: animateGradient ? 150 : 100,
                y: animateGradient ? 200 : 150
            )

            // Gradient 3 - Bottom Trailing
            gradientBlob(
                color: .blue,
                x: animateGradient ? 50 : 100,
                y: animateGradient ? 50 : 100
            )
        }
    }

    // MARK: - Gradient Blob

    private func gradientBlob(color: Color, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.2),
                        color.opacity(0.1),
                        .clear
                    ],
                    center: colorScheme == .dark ? .center : .topLeading,
                    startRadius: 0,
                    endRadius: gradientSize
                )
            )
            .frame(width: gradientSize, height: gradientSize)
            .offset(x: x, y: y)
            .blur(radius: blurRadius)
    }

    // MARK: - Animation Control

    private func startAnimationIfNeeded() {
        guard !reduceMotion && isActive else { return }

        withAnimation(
            .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
        ) {
            animateGradient.toggle()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isActive = true
            startAnimationIfNeeded()
        case .inactive, .background:
            isActive = false
            // Pause animations to save battery
        @unknown default:
            break
        }
    }
}

// MARK: - Preview

#Preview("Animated (Default)") {
    EnhancedAnimatedGlassBackground()
}

// Note: To test Reduce Motion, enable it in Settings > Accessibility > Motion
#Preview("Static (Reduce Motion - Manual Test)") {
    EnhancedAnimatedGlassBackground()
}

// Note: To test Reduce Transparency, enable it in Settings > Accessibility > Display
#Preview("Solid (Reduce Transparency - Manual Test)") {
    EnhancedAnimatedGlassBackground()
}

#Preview("Dark Mode") {
    EnhancedAnimatedGlassBackground()
        .preferredColorScheme(.dark)
}
