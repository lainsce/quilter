import Foundation

nonisolated struct HeadingItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let level: Int
    let textRange: NSRange

    init(
        id: UUID = UUID(),
        title: String,
        level: Int,
        textRange: NSRange
    ) {
        self.id = id
        self.title = title
        self.level = level
        self.textRange = textRange
    }
}
