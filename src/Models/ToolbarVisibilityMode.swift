import Foundation

enum ToolbarVisibilityMode: String, CaseIterable, Identifiable {
    case alwaysHidden
    case hover
    case alwaysShown

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .alwaysHidden: "Always hidden"
        case .hover: "Hover"
        case .alwaysShown: "Always show"
        }
    }
}
