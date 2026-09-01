import AppKit
import SwiftUI

enum AppTheme {
    static let accentColor = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(srgbRed: 78 / 255, green: 165 / 255, blue: 241 / 255, alpha: 1)
            : NSColor(srgbRed: 36 / 255, green: 128 / 255, blue: 201 / 255, alpha: 1)
    })

    // Quilter's interface follows a small, predictable grid. Keeping these
    // values in one place makes the sidebar, toolbar, settings, and popovers
    // feel like parts of the same layout rather than individually tuned cards.
    static let gridUnit: CGFloat = 4
    static let gridGutter: CGFloat = gridUnit * 4
    static let gridSmallGap: CGFloat = gridUnit * 2
    static let gridSectionGap: CGFloat = gridUnit * 6
    static let gridContentInset: CGFloat = gridUnit * 8
    static let toolbarInset: CGFloat = gridUnit * 13
    static let toolbarLeadingInset: CGFloat = gridUnit * 24
    static let toolbarControlSize: CGFloat = 38
    static let toolbarIconSize: CGFloat = 22
    static let rowHeight: CGFloat = toolbarControlSize
    static let formRowSpacing: CGFloat = gridUnit * 4
    static let formLabelWidth: CGFloat = gridUnit * 32
    static let fieldHorizontalPadding: CGFloat = gridUnit * 3
    static let fieldHeight: CGFloat = gridUnit * 9

    // Geist Sans is used by the Metro-inspired interface. Old Standard TT is
    // reserved for view titles, while technical UI details use the bundled
    // Lekton family; document text remains in the user's selected editor font.
    static let uiFontFamily = "Geist"
    static let technicalFontFamily = "Lekton"

    enum TypographyRole: CaseIterable {
        case bigDisplay, display, viewTitle, viewSubtitle
        case contentBlockTitle, contentBlockSubtitle, body, caption, micro

        var size: CGFloat {
            switch self {
            case .bigDisplay: return 42
            case .display: return 32
            case .viewTitle: return 28
            case .viewSubtitle: return 24
            case .contentBlockTitle: return 18
            case .contentBlockSubtitle: return 16
            case .body: return 14
            case .caption: return 12
            case .micro: return 9
            }
        }

        var relativeTo: Font.TextStyle {
            switch self {
            case .bigDisplay, .display: return .largeTitle
            case .viewTitle: return .title
            case .viewSubtitle: return .title2
            case .contentBlockTitle: return .headline
            case .contentBlockSubtitle: return .subheadline
            case .body: return .body
            case .caption: return .caption
            case .micro: return .caption2
            }
        }
    }

    static func uiFont(role: TypographyRole) -> Font {
        if role == .viewTitle {
            return viewTitleFont(role)
        }
        let font = Font.custom(uiFontFamily, size: role.size, relativeTo: role.relativeTo)
        switch role {
        case .contentBlockTitle, .caption: return font.weight(.semibold)
        default: return font
        }
    }

    static func technicalFont(role: TypographyRole) -> Font {
        let font = Font.custom(technicalFontFamily, size: role.size, relativeTo: role.relativeTo)
        switch role {
        case .contentBlockTitle, .caption: return font.weight(.semibold)
        default: return font
        }
    }

    static let bigDisplay = uiFont(role: .bigDisplay)
    static let display = uiFont(role: .display)
    static let viewTitle = uiFont(role: .viewTitle)
    static let viewSubtitle = uiFont(role: .viewSubtitle)
    static let contentBlockTitle = uiFont(role: .contentBlockTitle)
    static let contentBlockSubtitle = uiFont(role: .contentBlockSubtitle)
    static let body = uiFont(role: .body)
    static let caption = uiFont(role: .caption)
    static let micro = uiFont(role: .micro)

    static func uiFont(
        size: CGFloat,
        weight _: Font.Weight = .regular,
        relativeTo _: Font.TextStyle = .body
    ) -> Font {
        uiFont(role: role(for: size))
    }

    static func technicalFont(
        size: CGFloat,
        weight _: Font.Weight = .regular,
        relativeTo _: Font.TextStyle = .body
    ) -> Font {
        technicalFont(role: role(for: size))
    }

    private static func role(for size: CGFloat) -> TypographyRole {
        let roles: [(lower: CGFloat, upper: CGFloat?, role: TypographyRole)] = [
            (38, nil, .bigDisplay),
            (30, 38, .display),
            (26, 30, .viewTitle),
            (21, 26, .viewSubtitle),
            (17, 21, .contentBlockTitle),
            (15, 17, .contentBlockSubtitle),
            (13, 15, .body),
            (11, 13, .caption),
        ]
        return roles.first { contains(size, lower: $0.lower, upper: $0.upper) }?.role ?? .micro
    }

    private static func contains(_ size: CGFloat, lower: CGFloat, upper: CGFloat?) -> Bool {
        guard size >= lower else { return false }
        guard let upper else { return true }
        return size < upper
    }

    /// Old Standard TT supplies the Latin view-title treatment. If the
    /// bundled face cannot be loaded, keep the role Dynamic Type-aware and
    /// fall back to an installed system Mincho family.
    private static func viewTitleFont(_ role: TypographyRole) -> Font {
        guard NSFont(name: "OldStandardTT-Regular", size: role.size) != nil else {
            for family in ["Hiragino Mincho ProN", "Hiragino Mincho Pro", "YuMincho", "Songti SC"]
                where NSFont(name: family, size: role.size) != nil {
                return .custom(family, size: role.size, relativeTo: role.relativeTo)
            }
            return .system(role.relativeTo, design: .serif)
        }
        return .custom("OldStandardTT-Regular", size: role.size, relativeTo: role.relativeTo)
    }

    // The content layer is intentionally quiet: system colors carry the
    // light/dark appearance and the accent is reserved for selection and
    // keyboard focus. These tokens keep the industrial treatment consistent
    // across the sidebar, settings, menus, and document chrome.
    static func industrialControlRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.16)
            : Color.black.opacity(0.12)
    }

    static func industrialQuietRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }
    private static let industrialLightSurfaceNSColor = NSColor(
        srgbRed: 253 / 255,
        green: 253 / 255,
        blue: 253 / 255,
        alpha: 1
    )
    private static let industrialDarkSurfaceNSColor = NSColor(
        srgbRed: 17 / 255,
        green: 17 / 255,
        blue: 17 / 255,
        alpha: 1
    )
    private static let editorLightSurfaceNSColor = NSColor(
        srgbRed: 242 / 255,
        green: 242 / 255,
        blue: 242 / 255,
        alpha: 1
    )
    private static let editorDarkSurfaceNSColor = NSColor(
        srgbRed: 17 / 255,
        green: 17 / 255,
        blue: 17 / 255,
        alpha: 1
    )
    private static let previewLightSurfaceNSColor = NSColor.white
    private static let previewDarkSurfaceNSColor = NSColor.black
    private static let previewLightTextNSColor = NSColor.black
    private static let previewDarkTextNSColor = NSColor.white

    static func industrialSurfaceColor(for appearance: NSAppearance) -> NSColor {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? industrialDarkSurfaceNSColor
            : industrialLightSurfaceNSColor
    }

    static func sidebarDividerColor(for appearance: NSAppearance) -> NSColor {
        (appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor.white
            : NSColor.black
        ).withAlphaComponent(0.12)
    }

    static func editorSurfaceColor(for appearance: NSAppearance) -> NSColor {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? editorDarkSurfaceNSColor
            : editorLightSurfaceNSColor
    }

    static func previewSurfaceColor(for appearance: NSAppearance) -> NSColor {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? previewDarkSurfaceNSColor
            : previewLightSurfaceNSColor
    }

    static func previewTextColor(for appearance: NSAppearance) -> NSColor {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? previewDarkTextNSColor
            : previewLightTextNSColor
    }

    /// Opaque item surface used above the industrial workspace. Keep the
    /// light/dark values explicit instead of inheriting the host window color.
    static var industrialSurface: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            industrialSurfaceColor(for: appearance)
        })
    }

    static func configuredEditorSurfaceColor() -> NSColor {
        NSColor(name: nil) { appearance in
            editorSurfaceColor(for: appearance)
        }
    }

    static func configuredPreviewSurfaceColor() -> NSColor {
        NSColor(name: nil) { appearance in
            previewSurfaceColor(for: appearance)
        }
    }

    static var industrialPanel: Color { industrialSurface }
    static let sidebarSelectedFillOpacity: Double = 0.14
    static let sidebarHoverFillOpacity: Double = 0.06
    static let sidebarSelectedBorderOpacity: Double = 0.72
    static let industrialCornerRadius: CGFloat = gridUnit
    static let industrialSmallCornerRadius: CGFloat = gridUnit
    static let industrialLargeCornerRadius: CGFloat = gridUnit * 3
    static let delimiterThickness: CGFloat = 1
    // Sidebar content sits eight points from the pane edges. Keep this
    // separate from the larger layout gutter used by document content.
    static let sidebarHorizontalPadding: CGFloat = gridUnit * 2
    static let sidebarSectionSpacing: CGFloat = gridSectionGap

    static let documentListCornerRadius: CGFloat = industrialCornerRadius

    /// Large workspace surfaces remain visibly distinct from the opaque item
    /// surfaces placed on top of them.
    static func workspaceBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0, green: 0, blue: 0)
            : Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
    }

    static func sidebarBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255)
            : Color(red: 228 / 255, green: 228 / 255, blue: 228 / 255)
    }

    static func sidebarDivider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    static func sidebarHoverFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(sidebarHoverFillOpacity)
            : Color.black.opacity(sidebarHoverFillOpacity)
    }

    static let toolbarRevealDuration: TimeInterval = 0.18
    static let toolbarHideDuration: TimeInterval = 0.14

    // A short, damped spring keeps sidebar/title state changes connected to
    // the user's gesture without introducing a decorative bounce.
    static let interfaceSpring = Animation.spring(
        response: 0.24,
        dampingFraction: 0.88
    )
    static let editorFontPointSize: CGFloat = 16
    static let editorLineHeight: CGFloat = 28

    static func accentCSSColor(
        alpha: Double = 1
    ) -> String {
        let nsColor = NSColor(accentColor)
        let srgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let r = Int((srgb.redComponent * 255).rounded())
        let g = Int((srgb.greenComponent * 255).rounded())
        let b = Int((srgb.blueComponent * 255).rounded())
        return "rgba(\(r), \(g), \(b), \(alpha))"
    }
}

struct MarkdownColumnLayout: Equatable {
    static let minimumHorizontalInset: CGFloat = 32
    static let verticalInset: CGFloat = 56

    let availableWidth: CGFloat
    let targetTextWidth: CGFloat
    let markerGutter: CGFloat
    let horizontalInset: CGFloat
    let readableWidth: CGFloat

    init(
        availableWidth: CGFloat,
        targetTextWidth: CGFloat,
        markerGutter: CGFloat
    ) {
        let safeAvailableWidth = max(0, availableWidth)
        let safeTextWidth = max(0, targetTextWidth)
        let safeMarkerGutter = max(0, markerGutter)
        let blockWidth = safeTextWidth + safeMarkerGutter

        self.availableWidth = safeAvailableWidth
        self.targetTextWidth = safeTextWidth
        self.markerGutter = safeMarkerGutter
        self.horizontalInset = max(
            Self.minimumHorizontalInset,
            floor((safeAvailableWidth - blockWidth) / 2)
        )
        self.readableWidth = max(
            0,
            safeAvailableWidth - (self.horizontalInset * 2) - safeMarkerGutter
        )
    }

    var leadingInset: CGFloat { horizontalInset + markerGutter }
    var trailingInset: CGFloat { horizontalInset }

    static func textWidth(font: NSFont, characterCount: Int) -> CGFloat {
        let sample = String(repeating: "x", count: max(0, characterCount)) as NSString
        return ceil(sample.size(withAttributes: [.font: font]).width)
    }
}

extension EnvironmentValues {
    @Entry var appAccentColor: Color = AppTheme.accentColor
}
