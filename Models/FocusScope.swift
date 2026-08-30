import Foundation

enum FocusScope: String, CaseIterable, Identifiable {
    case paragraph
    case sentence

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .paragraph: "Paragraph"
        case .sentence: "Sentence"
        }
    }
}
