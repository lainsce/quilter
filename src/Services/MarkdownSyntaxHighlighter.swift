import AppKit
import NaturalLanguage

@MainActor
enum MarkdownSyntaxHighlighter {
    static let headingExpression = expression(#"(?m)^(#{1,6})[\t ]+.*$"#)
    static let boldExpression = expression(
        #"(?<!\*)\*{2}([^\n]+?)\*{2}(?!\*)"#
    )
    static let italicExpression = expression(
        #"(?<![\p{L}\p{N}_])_([^_\n]+?)_(?![\p{L}\p{N}_])"#
    )
    static let strikethroughExpression = expression(#"(?<!~)~~([^~\n]+?)~~(?!~)"#)
    static let highlightExpression = expression(
        #"(?<![=])==([^=\n]+?)==(?![=])"#
    )
    static let uncheckedTaskExpression = expression(
        #"(?m)^[\t ]*[-*+][\t ]+\[[ ]?\]"#
    )
    static let checkedTaskExpression = expression(
        #"(?m)^[\t ]*[-*+][\t ]+\[[xX]\]"#
    )
    static let tableRowExpression = expression(
        #"(?m)^[\t ]*\|?[^|\n]+\|[^|\n]+(?:\|[^|\n]*)?\|?[\t ]*$"#
    )
    static let tableDelimiterExpression = expression(
        #"(?m)^[\t ]*\|?[\t ]*:?-{3,}:?[\t ]*(?:\|[\t ]*:?-{3,}:?[\t ]*)+\|?[\t ]*$"#
    )
    static let quoteExpression = expression(#"(?m)^[\t ]{0,3}>.*$"#)
    // Inline #tag: a "#" that is followed immediately by a letter (so it is not a
    // heading, which requires a space after the marker) and not preceded by a
    // word character, "#", or "/".
    static let tagExpression = expression(
        #"(?<![\p{L}\p{N}_/#])#[\p{L}][\p{L}\p{N}_/-]*"#
    )
    static let inlineCodeExpression = expression(#"(?<!`)`([^`\n]+)`(?!`)"#)
    static let horizontalRuleExpression = expression(
        #"(?m)^[\t ]{0,3}(?:(?:\*[\t ]*){3,}|(?:-[\t ]*){3,}|(?:_[\t ]*){3,})[\t ]*$"#
    )
    static let fencedCodeExpression = expression(
        #"(?ms)^[\t ]*(`{3,}|~{3,})[^\n]*\n.*?(?:^[\t ]*\1[\t ]*$|\z)"#
    )

}
