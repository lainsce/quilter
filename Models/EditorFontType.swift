import AppKit

enum EditorFontType: String, CaseIterable, Identifiable {
    case quiltMono
    case quiltZwei
    case quiltVier

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .quiltMono: "Quilt Mono"
        case .quiltZwei: "Quilt Zwei"
        case .quiltVier: "Quilt Vier"
        }
    }

    private var postScriptName: String {
        switch self {
        case .quiltMono: "QuiltMono"
        case .quiltZwei: "Quilt-Zwei"
        case .quiltVier: "QuiltVier"
        }
    }

    func font(ofSize size: CGFloat, traits: NSFontTraitMask = []) -> NSFont {
        let baseFont = NSFont(name: postScriptName, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)

        guard !traits.isEmpty else { return baseFont }
        return NSFontManager.shared.convert(baseFont, toHaveTrait: traits)
    }

    /// Returns attributes for a bold Markdown run or heading. The bundled Quilt
    /// faces currently ship with a regular face only, so AppKit's trait
    /// conversion can legitimately return the unchanged font. A small negative
    /// stroke preserves the selected typeface while providing the synthetic
    /// weight that GTK/Pango applies when no bold face is installed.
    func boldTextAttributes(ofSize size: CGFloat) -> [NSAttributedString.Key: Any] {
        let boldFont = font(ofSize: size, traits: .boldFontMask)
        var attributes: [NSAttributedString.Key: Any] = [.font: boldFont]

        if !boldFont.fontDescriptor.symbolicTraits.contains(.bold) {
            attributes[.strokeWidth] = -7
        }

        return attributes
    }
}
