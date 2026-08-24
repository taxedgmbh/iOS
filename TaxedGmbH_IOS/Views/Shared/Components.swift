//
//  Components.swift
//  TaxedGmbH_IOS
//
//  The small shared pieces. Touch targets are 44pt minimum throughout, which is
//  the Apple HIG floor and not negotiable on a form people fill in on a train.
//

import SwiftUI

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(minHeight: 48)
            .padding(.horizontal, .paddingRelaxed)
            .background(Color.taxedPrimary.opacity(isEnabled ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Color.taxedPrimary)
            .frame(minHeight: 48)
            .padding(.horizontal, .paddingRelaxed)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .strokeBorder(Color.taxedPrimary.opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .foregroundStyle(Color.taxedPrimary)
            .frame(minHeight: 44)
            .padding(.horizontal, .paddingTight)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

// MARK: - Fields

struct AuthField: View {
    let title: String
    @Binding var text: String
    var isSecure = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacingStandard) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
            .autocorrectionDisabled(keyboard == .emailAddress)
            .frame(minHeight: 44)
            .padding(.horizontal, .paddingStandard)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
            .accessibilityLabel(title)
        }
    }
}

// MARK: - Messaging

/// One error presentation for the whole app.
///
/// It shows what the server said and nothing more. Two errors deliberately read
/// the same — "not found" and "not yours" — because distinguishing them would
/// let anyone probe which household ids exist.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: .paddingStandard) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.brandRed)
                .accessibilityHidden(true)
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.paddingStandard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandRed.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

/// A centred explanation with room for one or two actions. Used for every state
/// that is not a list: pending approval, no documents yet, staff.
struct MessageScreen<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        ScrollView {
            VStack(spacing: .paddingRelaxed) {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.taxedPrimary)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: .paddingTight) { actions }
                    .padding(.top, .paddingTight)
            }
            .padding(.paddingSpacious)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primaryBackground)
    }
}

// MARK: - Brand

extension Color {
    /// The Swiss accent from the brand system, used as a hairline signature and
    /// for errors. Matches `brand-red` #C7242E on the web.
    static let brandRed = Color(red: 0.780, green: 0.141, blue: 0.180)
}

// MARK: - Formatting

enum Format {
    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: bytes)
    }

    static func date(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
