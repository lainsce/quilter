import Foundation

/// Compiled phrase sets for the optional writing-style checks.
///
/// Keeping these expressions separate from the syntax highlighter makes the
/// editor's Markdown rules easier to scan and lets the phrase vocabulary grow
/// without making the rendering code harder to maintain.
@MainActor
enum MarkdownStyleCheckerExpressions {
    static let clicheExpression = phraseExpression(clichePhrases)
    static let redundancyExpression = phraseExpression(redundancyPhrases)
    static let fillerExpression = phraseExpression(fillerPhrases)

    private static func phraseExpression(_ phrases: [String]) -> NSRegularExpression? {
        let alternatives = phrases
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
            .map {
                NSRegularExpression.escapedPattern(for: $0)
                    .replacingOccurrences(of: " ", with: #"[\t ]+"#)
            }
            .joined(separator: "|")

        guard !alternatives.isEmpty else { return nil }

        let pattern = #"(?i)(?<![\p{L}\p{N}_])(?:"# +
            alternatives +
            #")(?![\p{L}\p{N}_])"#
        return try? NSRegularExpression(pattern: pattern)
    }
}
