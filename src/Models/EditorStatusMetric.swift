import Foundation

enum EditorStatusMetric: String, CaseIterable, Identifiable {
    static let selectionDefaultsKey = "Quilter.EditorStatusMetric"

    case sentences
    case words
    case readingTime

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .sentences:
            "Sentences"
        case .words:
            "Words"
        case .readingTime:
            "Reading Time"
        }
    }

    var systemImage: String {
        switch self {
        case .sentences:
            "text.line.first.and.arrowtriangle.forward"
        case .words:
            "textformat.abc"
        case .readingTime:
            "clock"
        }
    }

    func displayText(for document: DocumentItem) -> LocalizedStringResource {
        switch self {
        case .sentences:
            "^[\(document.sentenceCount) sentence](inflect: true)"
        case .words:
            "^[\(document.wordCount) word](inflect: true)"
        case .readingTime:
            "Reading time: ^[\(document.readingTimeMinutes) minute](inflect: true)"
        }
    }
}
