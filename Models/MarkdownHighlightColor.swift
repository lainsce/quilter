import AppKit
import Foundation

/// The background tint used by the `==highlighted text==` Markdown syntax.
enum MarkdownHighlightColor: String, CaseIterable, Identifiable {
    case yellow
    case orange
    case pink
    case purple
    case blue
    case green

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .yellow: "Yellow"
        case .orange: "Orange"
        case .pink: "Pink"
        case .purple: "Purple"
        case .blue: "Blue"
        case .green: "Green"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .yellow: .systemYellow
        case .orange: .systemOrange
        case .pink: .systemPink
        case .purple: .systemPurple
        case .blue: .systemBlue
        case .green: .systemGreen
        }
    }
}
