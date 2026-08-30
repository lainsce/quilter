import Foundation

nonisolated struct MarkdownDerivedState: Sendable {
    let headings: [HeadingItem]
    let tags: [String]
    let sentenceCount: Int
    let wordCount: Int
}
