import Foundation

struct EditorScrollTarget: Equatable, Sendable {
    let id = UUID()
    let range: NSRange
}
