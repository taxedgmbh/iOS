//
//  SignInMasthead.swift
//  TaxedGmbH_IOS
//
//  The one memorable thing on the sign-in screen.
//
//  A photograph of the Lauterbrunnen valley, with the wordmark CUT OUT of a
//  brand-red plate laid over it — so TAXED is not printed on the picture, it is
//  a hole through which the picture is visible. The letterforms are the window.
//
//  Why this and not a photo behind the whole screen, which is the obvious move:
//  a full-bleed photograph under a login form is a contrast problem that never
//  fully resolves. Text fields need a quiet surface. Confining the image to a
//  masthead lets the picture be at full strength — no 25% opacity, no scrim
//  fighting it — while the form below sits on plain background and stays
//  legible at AA. The photograph earns its place by being uncompromised in the
//  third of the screen it occupies, rather than washed out across all of it.
//
//  The red plate is the logo plate from the brand system, the same one the mark
//  sits on everywhere else; cutting the name out of it is the identity doing
//  the work rather than an effect applied to it.
//

import SwiftUI

struct SignInMasthead: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifted = false

    /// Tall enough to hold the wordmark at a size that reads as a logo rather
    /// than a heading, short enough to leave both fields and the button above
    /// the keyboard on the smallest current iPhone.
    private let height: CGFloat = 236

    var body: some View {
        ZStack {
            photograph
            plate
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityElement()
        .accessibilityLabel(AppConstants.App.name)
        .accessibilityAddTraits(.isImage)
    }

    private var photograph: some View {
        Image("SignInBackdrop")
            .resizable()
            .scaledToFill()
            // A very slow push in. One effect, and only one: the knockout is
            // the idea, this just stops the picture reading as a screenshot.
            .scaleEffect(drifted ? 1.06 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 24).repeatForever(autoreverses: true),
                value: drifted
            )
            .onAppear { drifted = true }
    }

    /// The brand-red plate with the wordmark punched through it.
    ///
    /// `destinationOut` inside a `compositingGroup` is what does the cutting:
    /// the text erases the plate beneath it rather than drawing on top. Without
    /// the compositing group the blend would apply to everything already drawn,
    /// and knock a TAXED-shaped hole in the photograph as well.
    private var plate: some View {
        Rectangle()
            // Opaque, and that is the whole point. A translucent plate tints
            // the photograph pink and leaves the letters barely brighter than
            // their surroundings — neither a plate nor a window, just haze.
            // Solid, the letters become the only way through, and the valley
            // arrives at full saturation inside them.
            .fill(Color.brandRed)
            .overlay {
                Text(verbatim: "TAXED")
                    .font(BrandFont.display(size: 92, weight: 800))
                    // Tight, per the brand's display spec. At this size default
                    // tracking leaves the letters floating apart and the word
                    // stops reading as a mark.
                    .tracking(-3)
                    .lineLimit(1)
                    // The word must never clip: on a narrow device it shrinks
                    // rather than losing its D.
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, .paddingSpacious)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}
