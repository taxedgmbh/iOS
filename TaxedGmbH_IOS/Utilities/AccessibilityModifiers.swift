//
//  AccessibilityModifiers.swift
//  TaxedGmbH_IOS
//
//  Comprehensive SwiftUI accessibility modifiers
//  Following Apple HIG accessibility guidelines
//

import SwiftUI

// MARK: - Accessibility Traits

struct AccessibilityTraitsModifier: ViewModifier {
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Custom Accessibility Actions

struct AccessibilityActionsModifier: ViewModifier {
    let actions: [AccessibilityCustomAction]

    func body(content: Content) -> some View {
        content
            .accessibilityActions {
                ForEach(actions, id: \.name) { action in
                    Button(action.name) {
                        action.action()
                    }
                }
            }
    }
}

struct AccessibilityCustomAction: Identifiable {
    let id = UUID()
    let name: String
    let action: () -> Void
}

// MARK: - Accessibility Rotor

struct AccessibilityRotorModifier: ViewModifier {
    let rotorLabel: String
    let entries: [String]
    @Binding var selection: String?

    func body(content: Content) -> some View {
        content
            .accessibilityRotor(rotorLabel) {
                ForEach(entries, id: \.self) { entry in
                    AccessibilityRotorEntry(entry, id: entry)
                }
            }
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let minSize: DynamicTypeSize
    let maxSize: DynamicTypeSize

    init(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .accessibility5) {
        self.minSize = min
        self.maxSize = max
    }

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(minSize...maxSize)
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
        }
    }
}

// MARK: - Reduce Transparency Support

struct ReduceTransparencyModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceTransparency ? 1.0 : opacity)
    }
}

// MARK: - High Contrast Support

struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        content
            .contrast(colorSchemeContrast == .increased ? 1.2 : 1.0)
    }
}

// MARK: - Voice Control Support

struct VoiceControlModifier: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityInputLabels([label])
    }
}

// MARK: - Minimum Touch Target

struct MinimumTouchTargetModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: accessibilityManager.minimumTouchTargetSize.width,
                minHeight: accessibilityManager.minimumTouchTargetSize.height
            )
    }
}

// MARK: - Accessibility Focus

struct AccessibilityFocusModifier: ViewModifier {
    @AccessibilityFocusState var isFocused: Bool
    let namespace: Namespace.ID
    let condition: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused, equals: condition)
    }
}

// MARK: - Accessibility Sort Priority

struct AccessibilitySortPriorityModifier: ViewModifier {
    let priority: Double

    func body(content: Content) -> some View {
        content
            .accessibilitySortPriority(priority)
    }
}

// MARK: - View Extensions

extension View {

    // MARK: - Comprehensive Accessibility

    /// Apply all essential accessibility features
    func accessibilityEssentials(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isHidden: Bool = false,
        sortPriority: Double = 0
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityHidden(isHidden)
            .accessibilitySortPriority(sortPriority)
    }

    // MARK: - Button Accessibility

    /// Optimize for accessible buttons
    func accessibleButton(
        label: String,
        hint: String? = nil,
        action: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Tap to \(action ?? "activate")")
            .accessibilityAddTraits(.isButton)
            .minimumTouchTarget()
    }

    // MARK: - Text Field Accessibility

    /// Optimize for accessible text fields
    func accessibleTextField(
        label: String,
        hint: String? = nil,
        value: String
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Enter \(label)")
            .accessibilityValue(value.isEmpty ? "Empty" : value)
            .accessibilityAddTraits(.isSearchField)
    }

    // MARK: - Image Accessibility

    /// Optimize for accessible images
    func accessibleImage(
        label: String,
        isDecorative: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(isDecorative ? "" : label)
            .accessibilityHidden(isDecorative)
            .accessibilityAddTraits(isDecorative ? [] : .isImage)
    }

    // MARK: - Navigation Accessibility

    /// Optimize for accessible navigation
    func accessibleNavigation(
        label: String,
        destination: String
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint("Navigate to \(destination)")
            .accessibilityAddTraits(.isLink)
    }

    // MARK: - Toggle Accessibility

    /// Optimize for accessible toggles
    func accessibleToggle(
        label: String,
        isOn: Bool,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint(hint ?? "Toggle \(label)")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - List Accessibility

    /// Optimize for accessible lists
    func accessibleList(
        itemCount: Int,
        currentIndex: Int? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityHint("\(itemCount) items")
            .accessibilityValue(currentIndex != nil ? "Item \(currentIndex! + 1) of \(itemCount)" : "")
    }

    // MARK: - Progress Accessibility

    /// Optimize for accessible progress indicators
    func accessibleProgress(
        value: Double,
        total: Double,
        label: String
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value)) of \(Int(total))")
            .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Alert Accessibility

    /// Optimize for accessible alerts
    func accessibleAlert(
        title: String,
        message: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityHint(message ?? "")
            .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Modifiers Application

    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }

    func dynamicTypeSupport(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .accessibility5) -> some View {
        modifier(DynamicTypeModifier(min: min, max: max))
    }

    func reduceMotionAware(animation: Animation? = .default) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }

    func reduceTransparencyAware(opacity: Double) -> some View {
        modifier(ReduceTransparencyModifier(opacity: opacity))
    }

    func highContrastAware() -> some View {
        modifier(HighContrastModifier())
    }

    func voiceControlOptimized(label: String, hint: String? = nil) -> some View {
        modifier(VoiceControlModifier(label: label, hint: hint))
    }

    func accessibilityRotor(_ label: String, entries: [String], selection: Binding<String?>) -> some View {
        modifier(AccessibilityRotorModifier(rotorLabel: label, entries: entries, selection: selection))
    }

    func accessibilityActions(_ actions: [AccessibilityCustomAction]) -> some View {
        modifier(AccessibilityActionsModifier(actions: actions))
    }

    func accessibilityTraits(_ traits: AccessibilityTraits) -> some View {
        modifier(AccessibilityTraitsModifier(traits: traits))
    }
}

// MARK: - Accessibility Announcements

struct AccessibilityAnnouncer {
    static func announce(
        _ message: String,
        delay: Double = 0,
        priority: UIAccessibility.Notification = .announcement
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }

    static func announceScreenChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    static func announceLayoutChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }
}

// MARK: - Accessibility Container

struct AccessibilityContainer<Content: View>: View {
    let label: String
    let hint: String?
    let elements: () -> Content

    init(
        label: String,
        hint: String? = nil,
        @ViewBuilder elements: @escaping () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.elements = elements
    }

    var body: some View {
        elements()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Accessibility Grouped Elements

struct AccessibilityGroup<Content: View>: View {
    let label: String
    let value: String?
    let content: () -> Content

    init(
        label: String,
        value: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.value = value
        self.content = content
    }

    var body: some View {
        content()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
    }
}