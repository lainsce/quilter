import CoreText
import Foundation

enum BundledFontRegistrar {
    static func registerFonts() {
        let fontURLs = Bundle.main.urls(
            forResourcesWithExtension: "ttf",
            subdirectory: "Fonts"
        ) ?? []

        for fontURL in fontURLs {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
