import Foundation

enum PreviewFontType: String, CaseIterable, Identifiable {
    case serif
    case sansSerif
    case monospace

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .serif: "Serif"
        case .sansSerif: "Sans-serif"
        case .monospace: "Monospace"
        }
    }

    var cssFamily: String {
        switch self {
        case .serif: "ui-serif, 'New York', Georgia, serif"
        case .sansSerif: "'Geist', -apple-system, BlinkMacSystemFont, sans-serif"
        case .monospace: "ui-monospace, 'SFMono-Regular', Menlo, monospace"
        }
    }
}
