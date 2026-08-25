//
//  Components.swift
//  TaxedGmbH_IOS
//
//  The small shared pieces. Touch targets are 44pt minimum throughout, which is
//  the Apple HIG floor and not negotiable on a form people fill in on a train.
//

import SwiftUI
import UIKit

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            // Full width belongs HERE, not on the Button. A style sizes its
            // background to the label, so `.frame(maxWidth: .infinity)` applied
            // outside stretches the tap target and leaves the fill hugging the
            // words — which is exactly how it looked.
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, .paddingRelaxed)
            .background(Color.taxedPrimary.opacity(isEnabled ? 1 : 0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            // Matched to the field radius, and the same height. The button is
            // the third item in a vertical rhythm of three; a different corner
            // on it is the kind of small inconsistency that reads as sloppy
            // without anyone being able to say why.
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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

/// A labelled text field wired for Password AutoFill and keyboard flow.
///
/// The `contentType` is the load-bearing part. Together with the
/// `webcredentials:taxed.ch` entitlement it is what makes iOS offer the
/// password already saved for the website, rather than a generic keychain
/// prompt — and on sign-up, offer to generate and save a strong one.
///
/// Focus is passed in rather than held here so the parent can move between
/// fields on Return. A sign-in form where Return does nothing is the small
/// friction people notice most.
struct AuthField<Field: Hashable>: View {
    let title: String
    @Binding var text: String
    let focus: FocusState<Field?>.Binding
    let field: Field

    var isSecure = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .return
    var onSubmit: () -> Void = {}

    @State private var revealed = false

    private var isEmail: Bool { keyboard == .emailAddress }
    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacingStandard) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: .paddingTight) {
                Group {
                    if isSecure && !revealed {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(isEmail ? .never : .sentences)
                .autocorrectionDisabled(isEmail)
                .submitLabel(submitLabel)
                .focused(focus, equals: field)
                .onSubmit(onSubmit)
                .accessibilityLabel(title)

                if isSecure {
                    revealButton
                }
            }
            .frame(minHeight: 52)
            .padding(.horizontal, .paddingRelaxed)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.taxedPrimary : Color.fieldBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
        }
        // The focus ring is the only thing that moves, and animating it makes
        // the jump between fields legible rather than a flicker.
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    /// Reveal the password.
    ///
    /// Its absence is one of the most common complaints about login forms, and
    /// the reason is mechanical: on a phone keyboard a long generated password
    /// is easy to mistype and impossible to check, so people give up and choose
    /// something short instead.
    private var revealButton: some View {
        Button {
            revealed.toggle()
            // Swapping SecureField for TextField tears down the responder, so
            // focus has to be re-asserted or the keyboard drops on every tap.
            focus.wrappedValue = field
        } label: {
            Image(systemName: revealed ? "eye.slash" : "eye")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            revealed ? "auth.password.hide".localized : "auth.password.show".localized
        )
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
    /// `brand-red` from the brand system — the logo plate and errors.
    ///
    /// #DD1F2F. Not #C7242E, which the brand tokens list as retired and which
    /// this app was using because it was copied from an older note.
    ///
    /// The tokens also name red as the primary action colour, but the portal's
    /// own sign-in button on taxed.ch is steel-blue, and this app matches the
    /// screen it is a copy of rather than the general rule. Steel-blue also
    /// carries white at 7.16:1 against red's 4.87:1.
    static let brandRed = Color(red: 0.867, green: 0.122, blue: 0.184)

    /// `border` #D2D9E0 — hairlines and input borders.
    ///
    /// A field that is only a grey fill reads as a block; the hairline is what
    /// makes it read as something you can type into.
    static let fieldBorder = Color(red: 0.824, green: 0.851, blue: 0.878).opacity(0.9)
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
