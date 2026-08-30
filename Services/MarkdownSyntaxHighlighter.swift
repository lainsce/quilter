import AppKit
import NaturalLanguage

@MainActor
enum MarkdownSyntaxHighlighter {
    private static let headingExpression = expression(#"(?m)^(#{1,6})[\t ]+.*$"#)
    private static let boldExpression = expression(
        #"(?<!\*)\*{2}([^\n]+?)\*{2}(?!\*)"#
    )
    private static let italicExpression = expression(
        #"(?<![\p{L}\p{N}_])_([^_\n]+?)_(?![\p{L}\p{N}_])"#
    )
    private static let strikethroughExpression = expression(#"(?<!~)~~([^~\n]+?)~~(?!~)"#)
    private static let highlightExpression = expression(
        #"(?<![=])==([^=\n]+?)==(?![=])"#
    )
    private static let uncheckedTaskExpression = expression(
        #"(?m)^[\t ]*[-*+][\t ]+\[[ ]?\]"#
    )
    private static let checkedTaskExpression = expression(
        #"(?m)^[\t ]*[-*+][\t ]+\[[xX]\]"#
    )
    private static let tableRowExpression = expression(
        #"(?m)^[\t ]*\|?[^|\n]+\|[^|\n]+(?:\|[^|\n]*)?\|?[\t ]*$"#
    )
    private static let tableDelimiterExpression = expression(
        #"(?m)^[\t ]*\|?[\t ]*:?-{3,}:?[\t ]*(?:\|[\t ]*:?-{3,}:?[\t ]*)+\|?[\t ]*$"#
    )
    private static let quoteExpression = expression(#"(?m)^[\t ]{0,3}>.*$"#)
    // Inline #tag: a "#" that is followed immediately by a letter (so it is not a
    // heading, which requires a space after the marker) and not preceded by a
    // word character, "#", or "/".
    private static let tagExpression = expression(
        #"(?<![\p{L}\p{N}_/#])#[\p{L}][\p{L}\p{N}_/-]*"#
    )
    private static let inlineCodeExpression = expression(#"(?<!`)`([^`\n]+)`(?!`)"#)
    private static let horizontalRuleExpression = expression(
        #"(?m)^[\t ]{0,3}(?:(?:\*[\t ]*){3,}|(?:-[\t ]*){3,}|(?:_[\t ]*){3,})[\t ]*$"#
    )
    private static let fencedCodeExpression = expression(
        #"(?ms)^[\t ]*(`{3,}|~{3,})[^\n]*\n.*?(?:^[\t ]*\1[\t ]*$|\z)"#
    )
    static func apply(
        to textView: NSTextView,
        fontType: EditorFontType,
        textColor: NSColor = .labelColor,
        accentColor: NSColor = .controlAccentColor,
        highlightColor: NSColor,
        highlightsNouns: Bool,
        highlightsVerbs: Bool,
        highlightsAdjectives: Bool,
        highlightsAdverbs: Bool,
        highlightsConjunctions: Bool,
        checksCliches: Bool,
        checksRedundancies: Bool,
        checksFillers: Bool
    ) {
        guard let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let bodyFont = fontType.font(ofSize: AppTheme.editorFontPointSize)
        let boldAttributes = fontType.boldTextAttributes(ofSize: AppTheme.editorFontPointSize)
        let italicFont = fontType.font(ofSize: AppTheme.editorFontPointSize, traits: .italicFontMask)
        let codeFont = fontType.font(ofSize: AppTheme.editorFontPointSize)
        let baseAttributes = baseAttributes(for: textView, bodyFont: bodyFont, textColor: textColor)
        textView.typingAttributes = baseAttributes

        guard fullRange.length > 0 else { return }

        let undoManager = textView.undoManager
        let shouldRestoreUndoRegistration = undoManager?.isUndoRegistrationEnabled == true
        if shouldRestoreUndoRegistration {
            undoManager?.disableUndoRegistration()
        }

        textStorage.beginEditing()
        defer {
            textStorage.endEditing()
            if shouldRestoreUndoRegistration {
                undoManager?.enableUndoRegistration()
            }
        }

        textStorage.setAttributes(baseAttributes, range: fullRange)

        applyMatches(
            boldExpression,
            in: text,
            attributes: boldAttributes,
            to: textStorage
        )
        applyMatches(
            italicExpression,
            in: text,
            attributes: [.font: italicFont],
            to: textStorage
        )
        applyMatches(
            strikethroughExpression,
            in: text,
            attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: NSColor.secondaryLabelColor
            ],
            to: textStorage
        )
        applyMatches(
            highlightExpression,
            in: text,
            attributes: [
                .backgroundColor: highlightColor.withAlphaComponent(0.48)
            ],
            to: textStorage
        )
        applyMatches(
            quoteExpression,
            in: text,
            attributes: [
                .font: italicFont,
                .foregroundColor: NSColor.secondaryLabelColor
            ],
            to: textStorage
        )
        applyHeadings(
            in: text,
            fontType: fontType,
            attributes: boldAttributes,
            baseParagraphStyle: textView.defaultParagraphStyle,
            to: textStorage
        )
        applyTableStyling(
            in: text,
            fontType: fontType,
            to: textStorage
        )
        applyMatches(
            uncheckedTaskExpression,
            in: text,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor],
            to: textStorage
        )
        applyMatches(
            checkedTaskExpression,
            in: text,
            attributes: [
                .foregroundColor: accentColor,
                .backgroundColor: accentColor.withAlphaComponent(0.12)
            ],
            to: textStorage
        )
        applyMatches(
            tagExpression,
            in: text,
            attributes: [.foregroundColor: accentColor],
            to: textStorage
        )
        applyMatches(
            inlineCodeExpression,
            in: text,
            attributes: [
                .font: codeFont,
                .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.14)
            ],
            to: textStorage
        )
        applyMatches(
            horizontalRuleExpression,
            in: text,
            attributes: [
                .foregroundColor: NSColor.separatorColor,
                .kern: 2.0
            ],
            to: textStorage
        )

        if highlightsNouns || highlightsVerbs || highlightsAdjectives
            || highlightsAdverbs || highlightsConjunctions {
            applySpeechParts(
                in: text,
                to: textStorage,
                highlightsNouns: highlightsNouns,
                highlightsVerbs: highlightsVerbs,
                highlightsAdjectives: highlightsAdjectives,
                highlightsAdverbs: highlightsAdverbs,
                highlightsConjunctions: highlightsConjunctions
            )
        }

        if checksCliches || checksRedundancies || checksFillers {
            let excludedRanges = matchRanges(for: inlineCodeExpression, in: text)
                + matchRanges(for: fencedCodeExpression, in: text)
            applyStyleChecker(
                in: text,
                to: textStorage,
                checksCliches: checksCliches,
                checksRedundancies: checksRedundancies,
                checksFillers: checksFillers,
                excluding: excludedRanges
            )
        }

        // Code fences are applied last so Markdown-looking text inside them stays code.
        applyMatches(
            fencedCodeExpression,
            in: text,
            attributes: [
                .font: codeFont,
                .foregroundColor: NSColor.secondaryLabelColor,
                .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.12),
                .strikethroughStyle: 0,
                .kern: 0
            ],
            to: textStorage
        )
    }

    static func applyFocusScope(
        to textView: NSTextView,
        scope: FocusScope,
        caretLocation: Int
    ) {
        guard let textStorage = textView.textStorage,
              let layoutManager = textView.layoutManager else {
            return
        }
        let text = textStorage.string
        let length = (text as NSString).length
        guard length > 0 else { return }

        let activeRange = activeRange(
            in: text,
            scope: scope,
            caretLocation: min(max(0, caretLocation), length)
        )
        let inactiveColor = NSColor.tertiaryLabelColor

        if activeRange.location > 0 {
            layoutManager.addTemporaryAttribute(
                .foregroundColor,
                value: inactiveColor,
                forCharacterRange: NSRange(location: 0, length: activeRange.location)
            )
        }

        let activeEnd = NSMaxRange(activeRange)
        if activeEnd < length {
            layoutManager.addTemporaryAttribute(
                .foregroundColor,
                value: inactiveColor,
                forCharacterRange: NSRange(location: activeEnd, length: length - activeEnd)
            )
        }
    }

    static func clearFocusScope(in textView: NSTextView) {
        guard let layoutManager = textView.layoutManager else { return }
        let length = (textView.string as NSString).length
        guard length > 0 else { return }
        layoutManager.removeTemporaryAttribute(
            .foregroundColor,
            forCharacterRange: NSRange(location: 0, length: length)
        )
    }

    private static func baseAttributes(
        for textView: NSTextView,
        bodyFont: NSFont,
        textColor: NSColor
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]
        if let paragraphStyle = textView.defaultParagraphStyle {
            attributes[.paragraphStyle] = paragraphStyle
        }
        return attributes
    }

    private static func applyHeadings(
        in text: String,
        fontType: EditorFontType,
        attributes: [NSAttributedString.Key: Any],
        baseParagraphStyle: NSParagraphStyle?,
        to textStorage: NSTextStorage
    ) {
        guard let headingExpression else { return }
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        // The body text of every heading (and of ordinary paragraphs) sits at a
        // fixed gutter equal to the widest marker, "###### ". Each heading's
        // first line is indented less than that gutter so its "#" marker hangs
        // to the left of the shared body column; deeper headings have wider
        // markers and therefore reach further left.
        let font = headingFont(for: 1, fontType: fontType)
        let gutter = headingIndent(for: fontType, maxLevel: maxHeadingLevel(in: text))

        headingExpression.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }
            let level = match.range(at: 1).length

            let style = (baseParagraphStyle?.mutableCopy() as? NSMutableParagraphStyle)
                ?? NSMutableParagraphStyle()
            // Preserve spacing authored in the Markdown itself. In particular,
            // an empty paragraph between headings should be the only source of
            // the larger visual gap in the editor.
            style.paragraphSpacing = 0
            style.paragraphSpacingBefore = 0
            style.firstLineHeadIndent = max(0, gutter - markerWidth(for: level, font: font))
            style.headIndent = gutter

            textStorage.addAttributes(
                [.font: font, .paragraphStyle: style],
                range: match.range
            )
            textStorage.addAttributes(attributes, range: match.range)
        }
    }

    private static func applyTableStyling(
        in text: String,
        fontType: EditorFontType,
        to textStorage: NSTextStorage
    ) {
        guard let tableDelimiterExpression else { return }

        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)
        let headerAttributes = fontType.boldTextAttributes(
            ofSize: AppTheme.editorFontPointSize
        )
        let delimiterAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .kern: 0.8
        ]

        tableDelimiterExpression.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }

            textStorage.addAttributes(delimiterAttributes, range: match.range)

            guard match.range.location > 0,
                  let tableRowExpression else {
                return
            }

            let previousLineRange = source.lineRange(
                for: NSRange(location: match.range.location - 1, length: 0)
            )
            let previousLine = source.substring(with: previousLineRange)
            let previousLineContent = previousLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let localContentRange = previousLine.range(of: previousLineContent) else {
                return
            }
            let localContentNSRange = NSRange(localContentRange, in: previousLine)
            let previousContentRange = NSRange(
                location: previousLineRange.location + localContentNSRange.location,
                length: localContentNSRange.length
            )

            guard tableRowExpression.firstMatch(
                in: previousLineContent,
                range: NSRange(location: 0, length: (previousLineContent as NSString).length)
            ) != nil else {
                return
            }

            textStorage.addAttributes(headerAttributes, range: previousContentRange)
        }
    }

    /// Width of the deepest heading marker present (e.g. "### " when the
    /// document's deepest heading is level 3), used as the shared left gutter so
    /// heading bodies align with ordinary paragraph text. Returns 0 when the
    /// document has no headings, so no gutter is reserved.
    static func headingIndent(for fontType: EditorFontType, maxLevel: Int) -> CGFloat {
        guard maxLevel > 0 else { return 0 }
        return markerWidth(for: min(6, maxLevel), font: headingFont(for: 1, fontType: fontType))
    }

    /// The deepest heading level (number of leading "#") in the document, or 0
    /// if there are no headings.
    static func maxHeadingLevel(in text: String) -> Int {
        guard let headingExpression else { return 0 }
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        var maxLevel = 0
        headingExpression.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }
            maxLevel = max(maxLevel, match.range(at: 1).length)
        }
        return maxLevel
    }

    private static func markerWidth(for level: Int, font: NSFont) -> CGFloat {
        let marker = String(repeating: "#", count: level) + " "
        return (marker as NSString).size(withAttributes: [.font: font]).width
    }

    private static func headingFont(for level: Int, fontType: EditorFontType) -> NSFont {
        switch level {
        default:
            fontType.font(ofSize: AppTheme.editorFontPointSize, traits: .boldFontMask)
        }
    }

    private static func applySpeechParts(
        in text: String,
        to textStorage: NSTextStorage,
        highlightsNouns: Bool,
        highlightsVerbs: Bool,
        highlightsAdjectives: Bool,
        highlightsAdverbs: Bool,
        highlightsConjunctions: Bool
    ) {
        guard !text.isEmpty,
              NLLanguageRecognizer.dominantLanguage(for: text) == .english ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .simplifiedChinese ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .traditionalChinese ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .korean ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .japanese ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .portuguese ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .french ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .spanish ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .arabic ||
              NLLanguageRecognizer.dominantLanguage(for: text) == .hindi else {
            return
        }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(
            in: range,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitPunctuation, .omitWhitespace]
        ) { tag, tokenRange in
            let color: NSColor? = switch tag {
            case .noun: highlightsNouns ? .systemIndigo : nil
            case .verb: highlightsVerbs ? .systemPurple : nil
            case .adjective: highlightsAdjectives ? .systemPink : nil
            case .adverb: highlightsAdverbs ? .systemOrange : nil
            case .conjunction: highlightsConjunctions ? .systemTeal : nil
            default: nil
            }

            if let color {
                textStorage.addAttribute(
                    .foregroundColor,
                    value: color,
                    range: NSRange(tokenRange, in: text)
                )
            }
            return true
        }
    }

    private static func applyStyleChecker(
        in text: String,
        to textStorage: NSTextStorage,
        checksCliches: Bool,
        checksRedundancies: Bool,
        checksFillers: Bool,
        excluding excludedRanges: [NSRange]
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.tertiaryLabelColor,
            .strikethroughStyle: NSUnderlineStyle.thick.rawValue,
            .strikethroughColor: NSColor.secondaryLabelColor
        ]

        if checksCliches {
            applyMatches(
                MarkdownStyleCheckerExpressions.clicheExpression,
                in: text,
                attributes: attributes,
                to: textStorage,
                excluding: excludedRanges
            )
        }
        if checksRedundancies {
            applyMatches(
                MarkdownStyleCheckerExpressions.redundancyExpression,
                in: text,
                attributes: attributes,
                to: textStorage,
                excluding: excludedRanges
            )
        }
        if checksFillers {
            applyMatches(
                MarkdownStyleCheckerExpressions.fillerExpression,
                in: text,
                attributes: attributes,
                to: textStorage,
                excluding: excludedRanges
            )
        }
    }

    private static func activeRange(
        in text: String,
        scope: FocusScope,
        caretLocation: Int
    ) -> NSRange {
        let nsText = text as NSString
        switch scope {
        case .paragraph:
            let location = min(caretLocation, max(0, nsText.length - 1))
            return nsText.paragraphRange(for: NSRange(location: location, length: 0))
        case .sentence:
            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.string = text
            let stringIndex = if caretLocation >= text.utf16.count {
                text.index(before: text.endIndex)
            } else {
                String.Index(utf16Offset: caretLocation, in: text)
            }
            let tokenRange = tokenizer.tokenRange(at: stringIndex)
            let range = NSRange(tokenRange, in: text)
            return range.length > 0 ? range : NSRange(location: 0, length: nsText.length)
        }
    }

    private static func applyMatches(
        _ expression: NSRegularExpression?,
        in text: String,
        attributes: [NSAttributedString.Key: Any],
        to textStorage: NSTextStorage,
        excluding excludedRanges: [NSRange] = []
    ) {
        guard let expression else { return }
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        expression.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }
            guard !excludedRanges.contains(where: {
                NSIntersectionRange(match.range, $0).length > 0
            }) else {
                return
            }
            textStorage.addAttributes(attributes, range: match.range)
        }
    }

    private static func matchRanges(
        for expression: NSRegularExpression?,
        in text: String
    ) -> [NSRange] {
        guard let expression else { return [] }
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        return expression.matches(in: text, range: fullRange).map(\.range)
    }

    private static func expression(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern)
    }
}
