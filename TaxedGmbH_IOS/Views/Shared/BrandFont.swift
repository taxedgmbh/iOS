//
//  BrandFont.swift
//  TaxedGmbH_IOS
//
//  Archivo, the typeface taxed.ch is set in.
//
//  Bundled rather than approximated with San Francisco, because the one place
//  it is used — the wordmark cut out of the sign-in masthead — is entirely
//  letterforms. A near-miss grotesque there reads as a different company.
//  Archivo is SIL Open Font Licence 1.1; the licence ships beside it in
//  Resources/Fonts/OFL.txt, which is what that licence requires.
//
//  It is a VARIABLE font, so weight is set on the `wght` axis directly rather
//  than by asking for a named face. Registering a variable font does not
//  reliably expose "Archivo-Black" and friends by name on iOS, and when it
//  fails it fails silently — you get Helvetica and no error.
//

import SwiftUI
import UIKit
import CoreText

enum BrandFont {
    /// The typographic family name from the font's `name` table.
    private static let family = "Archivo"

    /// OpenType `wght` axis, four-character code as a 32-bit integer.
    private static let weightAxis = 0x77676874

    /// Registers the bundled font with Core Text.
    ///
    /// Done in process at launch instead of through `UIAppFonts`, so the font
    /// travels with the file rather than with a build setting that a project
    /// edit can quietly drop.
    static func register() {
        guard let url = Bundle.main.url(forResource: "Archivo", withExtension: "ttf") else {
            assertionFailure("Archivo.ttf is missing from the bundle")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            // Already-registered is the only failure worth ignoring; it happens
            // on a SwiftUI preview reload.
            let code = CFErrorGetCode(error?.takeUnretainedValue())
            assert(code == CTFontManagerError.alreadyRegistered.rawValue,
                   "Could not register Archivo: \(String(describing: error))")
        }
    }

    /// Archivo at an explicit variable weight.
    ///
    /// - Parameter weight: `wght` axis value, 100–900. The brand's display
    ///   spec is 700; the wordmark uses more.
    static func display(size: CGFloat, weight: CGFloat = 700) -> Font {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            kCTFontVariationAttribute as UIFontDescriptor.AttributeName: [weightAxis: weight]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }
}
