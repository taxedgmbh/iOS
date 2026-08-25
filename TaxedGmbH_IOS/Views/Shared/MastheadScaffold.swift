//
//  MastheadScaffold.swift
//  TaxedGmbH_IOS
//
//  The shell every screen outside the portal wears: the knockout masthead, and
//  a sheet riding up over it.
//
//  Extracted from `SignInView` once a second screen needed it. Sign-in, waiting
//  for access and the staff notice are all things a person sees before they are
//  a client, and they should look like one product rather than one designed
//  screen followed by two plain ones.
//

import SwiftUI

struct MastheadScaffold<Content: View>: View {
    var maxContentWidth: CGFloat = 460
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            // Zero spacing: the masthead runs edge to edge and top to top, and
            // any gap above it shows as a band under the status bar.
            VStack(spacing: 0) {
                SignInMasthead()

                // The sheet rides UP over the masthead. That overlap is the
                // depth cue: the plate visibly continues behind the content
                // instead of stopping at a seam.
                content
                    .padding(.paddingSpacious)
                    // Runs the sheet past the last control to the bottom of the
                    // screen, so its shadow does not draw a seam across an
                    // otherwise empty page.
                    .padding(.bottom, 160)
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            topTrailingRadius: 28,
                            style: .continuous
                        )
                        .fill(Color.primaryBackground)
                        .shadow(color: .black.opacity(0.18), radius: 16, y: -4)
                    )
                    .offset(y: -28)
                    .padding(.bottom, -28)
            }
            // Pinned to the container width. Without it the masthead's
            // `maxWidth: .infinity` and the content's `maxWidth: 460` resolve
            // against an unbounded proposal inside the scroll view, the content
            // lays out at 460 on a 402pt screen, and both edges clip.
            .containerRelativeFrame(.horizontal)
        }
        .background(Color.primaryBackground)
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(edges: .top)
    }
}

/// A heading and explanation in the house style, for the screens that are a
/// statement rather than a form.
struct ScaffoldHeader: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
            Text(title)
                .font(BrandFont.display(size: 30, weight: 700))
                .fixedSize(horizontal: false, vertical: true)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, .paddingTight)
    }
}
