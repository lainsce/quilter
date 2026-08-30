import Foundation
import NaturalLanguage

nonisolated enum MarkdownParser {
    private static let headingExpression = try? NSRegularExpression(
        pattern: #"(?m)^(#{1,6})[\t ]+(.+?)[\t ]*#*[\t ]*$"#
    )
    private static let tagExpression = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\p{N}_/#])#([\p{L}][\p{L}\p{N}_/-]*)"#
    )

    static func derivedState(in text: String) -> MarkdownDerivedState {
        MarkdownDerivedState(
            headings: headings(in: text),
            tags: tags(in: text),
            sentenceCount: sentenceCount(in: text),
            wordCount: wordCount(in: text)
        )
    }

    /// Unique inline #tags in document order, de-duplicated case-insensitively
    /// while preserving the casing of the first occurrence.
    static func tags(in text: String) -> [String] {
        guard let tagExpression else { return [] }

        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)

        var seen = Set<String>()
        var result: [String] = []
        for match in tagExpression.matches(in: text, range: fullRange) {
            let tag = source.substring(with: match.range(at: 1))
            if seen.insert(tag.lowercased()).inserted {
                result.append(tag)
            }
        }
        return result
    }

    static func headings(in text: String) -> [HeadingItem] {
        guard let headingExpression else { return [] }

        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)

        return headingExpression.matches(in: text, range: fullRange).compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }

            let markerRange = match.range(at: 1)
            let titleRange = match.range(at: 2)
            guard markerRange.location != NSNotFound,
                  titleRange.location != NSNotFound else {
                return nil
            }

            let title = source.substring(with: titleRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !title.isEmpty else { return nil }

            return HeadingItem(
                title: title,
                level: markerRange.length,
                textRange: match.range
            )
        }
    }

    static func sentenceCount(in text: String) -> Int {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }

    static func wordCount(in text: String) -> Int {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }
}
