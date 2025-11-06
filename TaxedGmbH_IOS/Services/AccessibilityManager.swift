//
//  AccessibilityManager.swift
//  TaxedGmbH_IOS
//
//  Centralized accessibility management following Apple HIG
//  https://developer.apple.com/design/human-interface-guidelines/accessibility
//  https://developer.apple.com/documentation/accessibility
//

import SwiftUI
import UIKit
import Combine

/// Comprehensive accessibility manager for TaxedGmbH app
/// Implements all Apple accessibility features and guidelines
@MainActor
final class AccessibilityManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AccessibilityManager()

    // MARK: - Published Properties

    // Visual Accessibility
    @Published var isVoiceOverRunning: Bool = false
    @Published var isSwitchControlRunning: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isReduceTransparencyEnabled: Bool = false
    @Published var isDarkerSystemColorsEnabled: Bool = false
    @Published var isIncreaseContrastEnabled: Bool = false
    @Published var isInvertColorsEnabled: Bool = false
    @Published var isDifferentiateWithoutColorEnabled: Bool = false
    @Published var isOnOffSwitchLabelsEnabled: Bool = false
    @Published var isBoldTextEnabled: Bool = false
    @Published var isGrayscaleEnabled: Bool = false
    @Published var prefersCrossFadeTransitions: Bool = false

    // Hearing Accessibility
    @Published var isMonoAudioEnabled: Bool = false
    @Published var isClosedCaptioningEnabled: Bool = false

    // Motor Accessibility
    @Published var isAssistiveTouchRunning: Bool = false
    @Published var isShakeToUndoEnabled: Bool = false

    // Learning Accessibility
    @Published var isGuidedAccessEnabled: Bool = false
    @Published var isSpeakScreenEnabled: Bool = false
    @Published var isSpeakSelectionEnabled: Bool = false

    // Text Size
    @Published var dynamicTypeSize: DynamicTypeSize = .medium
    @Published var preferredContentSizeCategory: UIContentSizeCategory = .medium

    // Announcements
    @Published var lastAnnouncement: String = ""

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupAccessibilityObservers()
        updateAccessibilityStatus()
    }

    // MARK: - Setup

    private func setupAccessibilityObservers() {
        // Observe VoiceOver status changes
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Switch Control status changes
        NotificationCenter.default.publisher(for: UIAccessibility.switchControlStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Reduce Motion changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Reduce Transparency changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Bold Text changes
        NotificationCenter.default.publisher(for: UIAccessibility.boldTextStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Darker System Colors changes
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Grayscale changes
        NotificationCenter.default.publisher(for: UIAccessibility.grayscaleStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Invert Colors changes
        NotificationCenter.default.publisher(for: UIAccessibility.invertColorsStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Mono Audio changes
        NotificationCenter.default.publisher(for: UIAccessibility.monoAudioStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Closed Captioning changes
        NotificationCenter.default.publisher(for: UIAccessibility.closedCaptioningStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Guided Access changes
        NotificationCenter.default.publisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Speak Screen changes
        NotificationCenter.default.publisher(for: UIAccessibility.speakScreenStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Speak Selection changes
        NotificationCenter.default.publisher(for: UIAccessibility.speakSelectionStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Assistive Touch changes
        NotificationCenter.default.publisher(for: UIAccessibility.assistiveTouchStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Shake to Undo changes
        NotificationCenter.default.publisher(for: UIAccessibility.shakeToUndoDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAccessibilityStatus()
            }
            .store(in: &cancellables)

        // Observe Content Size Category changes
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateContentSizeCategory()
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Status

    private func updateAccessibilityStatus() {
        // Visual
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        isIncreaseContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        isGrayscaleEnabled = UIAccessibility.isGrayscaleEnabled
        prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
        isOnOffSwitchLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled

        // Hearing
        isMonoAudioEnabled = UIAccessibility.isMonoAudioEnabled
        isClosedCaptioningEnabled = UIAccessibility.isClosedCaptioningEnabled

        // Motor
        isAssistiveTouchRunning = UIAccessibility.isAssistiveTouchRunning
        isShakeToUndoEnabled = UIAccessibility.isShakeToUndoEnabled

        // Learning
        isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
        isSpeakScreenEnabled = UIAccessibility.isSpeakScreenEnabled
        isSpeakSelectionEnabled = UIAccessibility.isSpeakSelectionEnabled

        print("♿ Accessibility Status Updated")
        print("  - VoiceOver: \(isVoiceOverRunning)")
        print("  - Reduce Motion: \(isReduceMotionEnabled)")
        print("  - Bold Text: \(isBoldTextEnabled)")
        print("  - Dynamic Type: \(preferredContentSizeCategory)")
    }

    private func updateContentSizeCategory() {
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        // Map to SwiftUI DynamicTypeSize
        dynamicTypeSize = mapContentSizeToDynamicType(preferredContentSizeCategory)
    }

    // MARK: - Announcements

    /// Post accessibility announcement for VoiceOver
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        lastAnnouncement = message
        UIAccessibility.post(notification: priority, argument: message)
    }

    /// Post screen change notification
    func announceScreenChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    /// Post layout change notification
    func announceLayoutChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }

    /// Post page scrolled notification
    func announcePageScrolled(_ message: String) {
        UIAccessibility.post(notification: .pageScrolled, argument: message)
    }

    // MARK: - Focus Management

    /// Set accessibility focus to specific element
    func setFocus(to element: Any?) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }

    /// Check if element has focus
    /// Note: Direct comparison of focused element is not straightforward in iOS
    /// This is a placeholder that always returns false for now
    func isElementFocused(_ element: AnyObject) -> Bool {
        // TODO: Implement proper focus checking when needed
        return false
    }

    // MARK: - Helper Methods

    /// Map UIContentSizeCategory to SwiftUI DynamicTypeSize
    private func mapContentSizeToDynamicType(_ category: UIContentSizeCategory) -> DynamicTypeSize {
        switch category {
        case .extraSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        case .extraExtraLarge: return .xxLarge
        case .extraExtraExtraLarge: return .xxxLarge
        case .accessibilityMedium: return .accessibility1
        case .accessibilityLarge: return .accessibility2
        case .accessibilityExtraLarge: return .accessibility3
        case .accessibilityExtraExtraLarge: return .accessibility4
        case .accessibilityExtraExtraExtraLarge: return .accessibility5
        default: return .medium
        }
    }

    /// Get appropriate animation based on accessibility settings
    func accessibleAnimation<V: Equatable>(_ value: V) -> Animation? {
        return isReduceMotionEnabled ? nil : .default
    }

    /// Get appropriate transition based on accessibility settings
    func accessibleTransition() -> AnyTransition {
        if isReduceMotionEnabled || prefersCrossFadeTransitions {
            return .opacity
        }
        return .slide
    }

    /// Check if high contrast is needed
    func needsHighContrast() -> Bool {
        return isIncreaseContrastEnabled || isDarkerSystemColorsEnabled
    }

    /// Get accessible color with proper contrast
    func accessibleColor(for color: Color, background: Color = .clear) -> Color {
        if isIncreaseContrastEnabled {
            // Return high contrast version of color
            return color.opacity(1.0)
        }
        if isDarkerSystemColorsEnabled {
            // Return darker version for better visibility
            return color.opacity(0.9)
        }
        return color
    }

    /// Format text for accessibility
    func formatForAccessibility(_ text: String, context: String? = nil) -> String {
        if let context = context {
            return "\(context): \(text)"
        }
        return text
    }

    /// Check if animations should be disabled
    var shouldDisableAnimations: Bool {
        return isReduceMotionEnabled || isVoiceOverRunning
    }

    /// Check if transparency should be reduced
    var shouldReduceTransparency: Bool {
        return isReduceTransparencyEnabled
    }

    /// Get minimum touch target size based on accessibility settings
    var minimumTouchTargetSize: CGSize {
        // Apple HIG recommends 44x44 points minimum
        let baseSize: CGFloat = 44

        // Increase for motor accessibility
        if isAssistiveTouchRunning {
            return CGSize(width: baseSize * 1.5, height: baseSize * 1.5)
        }

        // Increase for larger text sizes
        if preferredContentSizeCategory.isAccessibilityCategory {
            return CGSize(width: baseSize * 1.25, height: baseSize * 1.25)
        }

        return CGSize(width: baseSize, height: baseSize)
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Apply comprehensive accessibility modifiers
    func accessibilityOptimized() -> some View {
        self
            .environment(\.accessibilityManager, AccessibilityManager.shared)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }

    /// Apply accessible animations
    func accessibleAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(AccessibilityManager.shared.accessibleAnimation(value), value: value)
    }

    /// Apply accessible transition
    func accessibleTransition() -> some View {
        self.transition(AccessibilityManager.shared.accessibleTransition())
    }
}

// MARK: - Environment Key

private struct AccessibilityManagerKey: EnvironmentKey {
    static let defaultValue = AccessibilityManager.shared
}

extension EnvironmentValues {
    var accessibilityManager: AccessibilityManager {
        get { self[AccessibilityManagerKey.self] }
        set { self[AccessibilityManagerKey.self] = newValue }
    }
}

// MARK: - UIContentSizeCategory Extension

extension UIContentSizeCategory {
    var isAccessibilityCategory: Bool {
        return self == .accessibilityMedium ||
               self == .accessibilityLarge ||
               self == .accessibilityExtraLarge ||
               self == .accessibilityExtraExtraLarge ||
               self == .accessibilityExtraExtraExtraLarge
    }
}