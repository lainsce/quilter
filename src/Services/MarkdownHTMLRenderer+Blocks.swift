import Foundation
import AppKit

extension MarkdownHTMLRenderer {
    static func renderBlocks(
        _ markdown: String,
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var html: [String] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                appendBlankLineIfNeeded(lines: lines, after: index, html: &html)
                index += 1
                continue
            }

            let block = renderBlock(
                line: line,
                trimmed: trimmed,
                lines: lines,
                at: index,
                rendersMermaid: rendersMermaid,
                visited: visited
            )
            html.append(block.html)
            index = block.nextIndex
        }

        return html.joined(separator: "\n")
    }

    private static func appendBlankLineIfNeeded(
        lines: [String],
        after index: Int,
        html: inout [String]
    ) {
        let hasFollowingContent = lines[(index + 1)...].contains {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        if !html.isEmpty && hasFollowingContent {
            html.append("<div class=\"quilter-blank-line\" aria-hidden=\"true\"></div>")
        }
    }

    static func renderBlock(
        line: String,
        trimmed: String,
        lines: [String],
        at index: Int,
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> (html: String, nextIndex: Int) {
        let candidate = blockCandidates(
            line: line,
            trimmed: trimmed,
            lines: lines,
            at: index,
            rendersMermaid: rendersMermaid,
            visited: visited
        ).compactMap { $0 }.first
        return candidate ?? paragraphBlock(in: lines, at: index)
    }

    private static func blockCandidates(
        line: String,
        trimmed: String,
        lines: [String],
        at index: Int,
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> [(html: String, nextIndex: Int)?] {
        let table = tableBlock(in: lines, startingAt: index).map {
            (html: renderTable($0), nextIndex: $0.nextIndex)
        }
        let headingBlock = heading(in: line).map {
            (html: "<h\($0.level)>\(renderInline($0.title))</h\($0.level)>", nextIndex: index + 1)
        }
        let ruleBlock: (html: String, nextIndex: Int)? = isHorizontalRule(trimmed)
            ? (html: "<hr>", nextIndex: index + 1)
            : nil
        return [
            fencedBlock(in: lines, at: index, rendersMermaid: rendersMermaid),
            directiveBlock(in: trimmed, at: index, rendersMermaid: rendersMermaid, visited: visited),
            table,
            headingBlock,
            ruleBlock,
            quoteBlock(in: lines, at: index),
            taskListBlock(in: lines, at: index),
            unorderedListBlock(in: lines, at: index),
            orderedListBlock(in: lines, at: index),
        ]
    }

    static func fencedBlock(
        in lines: [String],
        at index: Int,
        rendersMermaid: Bool
    ) -> (html: String, nextIndex: Int)? {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        guard let fence = fencePrefix(in: trimmed) else { return nil }
        let language = String(trimmed.dropFirst(fence.count)).trimmingCharacters(in: .whitespaces)
        let (codeLines, nextIndex) = fenceLines(in: lines, after: index, marker: fence)
        return fencedMarkup(language: language, code: escapeHTML(codeLines.joined(separator: "\n")), nextIndex: nextIndex, rendersMermaid: rendersMermaid)
    }

    private static func fenceLines(
        in lines: [String],
        after index: Int,
        marker: String
    ) -> ([String], Int) {
        var codeLines: [String] = []
        var nextIndex = index + 1
        while nextIndex < lines.count,
              !lines[nextIndex].trimmingCharacters(in: .whitespaces).hasPrefix(marker) {
            codeLines.append(lines[nextIndex])
            nextIndex += 1
        }
        if nextIndex < lines.count { nextIndex += 1 }
        return (codeLines, nextIndex)
    }

    private static func fencedMarkup(
        language: String,
        code: String,
        nextIndex: Int,
        rendersMermaid: Bool
    ) -> (html: String, nextIndex: Int) {
        if rendersMermaid, language.lowercased() == "mermaid" {
            return ("<div class=\"mermaid\">\(code)</div>", nextIndex)
        }
        let languageClass = language.isEmpty ? "" : " class=\"language-\(escapeAttribute(language))\""
        return ("<pre><code\(languageClass)>\(code)</code></pre>", nextIndex)
    }

    static func directiveBlock(
        in line: String,
        at index: Int,
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> (html: String, nextIndex: Int)? {
        guard let directive = inlineDirective(in: line) else { return nil }
        return (
            renderDirective(
                directive,
                rendersMermaid: rendersMermaid,
                visited: visited
            ),
            index + 1
        )
    }

    static func quoteBlock(
        in lines: [String],
        at index: Int
    ) -> (html: String, nextIndex: Int)? {
        let firstLine = lines[index].trimmingCharacters(in: .whitespaces)
        guard firstLine.hasPrefix(">") else { return nil }

        var quoteLines: [String] = []
        var nextIndex = index
        while nextIndex < lines.count {
            let quoteLine = lines[nextIndex].trimmingCharacters(in: .whitespaces)
            guard quoteLine.hasPrefix(">") else { break }
            quoteLines.append(
                String(quoteLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            )
            nextIndex += 1
        }
        return (
            "<blockquote>\(renderInline(quoteLines.joined(separator: " ")))</blockquote>",
            nextIndex
        )
    }

    static func taskListBlock(
        in lines: [String],
        at index: Int
    ) -> (html: String, nextIndex: Int)? {
        guard taskItem(in: lines[index]) != nil else { return nil }

        var items: [String] = []
        var nextIndex = index
        while nextIndex < lines.count, let task = taskItem(in: lines[nextIndex]) {
            let checkedAttribute = task.checked ? " checked" : ""
            let label = renderInline(task.text)
            items.append(
                "<li><input type=\"checkbox\" disabled\(checkedAttribute) "
                    + "aria-label=\"\(task.checked ? "Checked" : "Unchecked")\">"
                    + "<span>\(label)</span></li>"
            )
            nextIndex += 1
        }
        return ("<ul class=\"task-list\">\(items.joined())</ul>", nextIndex)
    }

    static func unorderedListBlock(
        in lines: [String],
        at index: Int
    ) -> (html: String, nextIndex: Int)? {
        guard unorderedItem(in: lines[index]) != nil else { return nil }

        var items: [String] = []
        var nextIndex = index
        while nextIndex < lines.count, let item = unorderedItem(in: lines[nextIndex]) {
            items.append("<li>\(renderInline(item))</li>")
            nextIndex += 1
        }
        return ("<ul>\(items.joined())</ul>", nextIndex)
    }

    static func orderedListBlock(
        in lines: [String],
        at index: Int
    ) -> (html: String, nextIndex: Int)? {
        guard orderedItem(in: lines[index]) != nil else { return nil }

        var items: [String] = []
        var nextIndex = index
        while nextIndex < lines.count, let item = orderedItem(in: lines[nextIndex]) {
            items.append("<li>\(renderInline(item))</li>")
            nextIndex += 1
        }
        return ("<ol>\(items.joined())</ol>", nextIndex)
    }

    static func paragraphBlock(
        in lines: [String],
        at index: Int
    ) -> (html: String, nextIndex: Int) {
        var paragraphLines = [lines[index].trimmingCharacters(in: .whitespaces)]
        var nextIndex = index + 1
        while nextIndex < lines.count,
              !startsBlock(
                  lines[nextIndex],
                  nextLine: nextIndex + 1 < lines.count ? lines[nextIndex + 1] : nil
              ) {
            let continuation = lines[nextIndex].trimmingCharacters(in: .whitespaces)
            guard !continuation.isEmpty else { break }
            paragraphLines.append(continuation)
            nextIndex += 1
        }
        return (
            "<p>\(renderInline(paragraphLines.joined(separator: " ")))</p>",
            nextIndex
        )
    }

    static func tableBlock(
        in lines: [String],
        startingAt index: Int
    ) -> (header: [String], alignments: [String], rows: [[String]], nextIndex: Int)? {
        guard index + 1 < lines.count,
              let header = tableCells(in: lines[index]),
              header.count >= 2,
              let delimiter = tableCells(in: lines[index + 1]),
              delimiter.count == header.count else {
            return nil
        }

        let alignments = delimiter.compactMap(tableAlignment)
        guard alignments.count == delimiter.count else { return nil }

        var rows: [[String]] = []
        var nextIndex = index + 2
        while nextIndex < lines.count, let row = tableCells(in: lines[nextIndex]) {
            rows.append(row)
            nextIndex += 1
        }

        return (header, alignments, rows, nextIndex)
    }

    static func renderTable(
        _ table: (header: [String], alignments: [String], rows: [[String]], nextIndex: Int)
    ) -> String {
        let headerCells = table.header.enumerated().map { index, cell in
            renderTableCell(
                cell,
                tag: "th",
                alignment: table.alignments[index]
            )
        }.joined()

        let bodyRows = table.rows.map { row in
            let cells = table.header.indices.map { index in
                let cell = index < row.count ? row[index] : ""
                return renderTableCell(
                    cell,
                    tag: "td",
                    alignment: table.alignments[index]
                )
            }.joined()
            return "<tr>\(cells)</tr>"
        }.joined()

        return "<div class=\"quilter-table-wrap\"><table>"
            + "<thead><tr>\(headerCells)</tr></thead>"
            + (bodyRows.isEmpty ? "" : "<tbody>\(bodyRows)</tbody>")
            + "</table></div>"
    }

    static func renderTableCell(
        _ source: String,
        tag: String,
        alignment: String
    ) -> String {
        let style = alignment.isEmpty ? "" : " style=\"text-align:\(alignment)\""
        let cell = source.replacingOccurrences(of: "\\|", with: "|")
        return "<\(tag)\(style)>\(renderInline(cell))</\(tag)>"
    }

    static func tableCells(in line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return nil }
        let cells = splitTableCells(normalizedTableContent(trimmed)).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard cells.count >= 2 else { return nil }
        return cells
    }

    private static func normalizedTableContent(_ content: String) -> String {
        var value = content
        if value.first == "|" { value.removeFirst() }
        if value.last == "|" { value.removeLast() }
        return value
    }

    static func splitTableCells(_ content: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var isEscaped = false
        var isInsideCodeSpan = false

        for character in content {
            guard !consumeEscaped(character, current: &current, isEscaped: &isEscaped) else { continue }
            guard !consumeDelimiter(character, current: &current, cells: &cells, isInsideCodeSpan: &isInsideCodeSpan) else { continue }
            current.append(character)
        }

        cells.append(current)
        return cells
    }

    private static func consumeEscaped(
        _ character: Character,
        current: inout String,
        isEscaped: inout Bool
    ) -> Bool {
        if isEscaped {
            current.append(character)
            isEscaped = false
            return true
        }
        guard character == "\\" else { return false }
        current.append(character)
        isEscaped = true
        return true
    }

    private static func consumeDelimiter(
        _ character: Character,
        current: inout String,
        cells: inout [String],
        isInsideCodeSpan: inout Bool
    ) -> Bool {
        if character == "`" {
            isInsideCodeSpan.toggle()
            current.append(character)
            return true
        }
        guard character == "|", !isInsideCodeSpan else { return false }
        cells.append(current)
        current = ""
        return true
    }

    static func tableAlignment(in cell: String) -> String? {
        var token = cell.trimmingCharacters(in: .whitespaces)
        let isLeftAligned = token.first == ":"
        let isRightAligned = token.last == ":"
        guard validTableDelimiter(&token) else { return nil }
        return alignmentName(left: isLeftAligned, right: isRightAligned)
    }

    private static func validTableDelimiter(_ token: inout String) -> Bool {
        guard token.count >= 3 else { return false }
        if token.first == ":" { token.removeFirst() }
        if token.last == ":" { token.removeLast() }
        return onlyDashes(token)
    }

    private static func onlyDashes(_ token: String) -> Bool {
        token.count >= 3 && token.allSatisfy { $0 == "-" }
    }

    private static func alignmentName(left: Bool, right: Bool) -> String {
        let index = (left ? 1 : 0) + (right ? 2 : 0)
        return [0: "", 1: "left", 2: "right", 3: "center"][index] ?? ""
    }

    static func taskItem(in line: String) -> (checked: Bool, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return parseTaskItem(trimmed)
    }

    private static func parseTaskItem(_ trimmed: String) -> (checked: Bool, text: String)? {
        let parts = trimmed.split(
            maxSplits: 1,
            omittingEmptySubsequences: true,
            whereSeparator: { $0.isWhitespace }
        )
        guard parts.count == 2, ["-", "*", "+"].contains(String(parts[0])) else { return nil }

        let markerAndText = parts[1]
        guard markerAndText.first == "[", let closingBracket = markerAndText.firstIndex(of: "]") else { return nil }

        let markerStart = markerAndText.index(after: markerAndText.startIndex)
        let marker = markerAndText[markerStart..<closingBracket]
        guard ["", " ", "x", "X"].contains(String(marker)) else { return nil }

        let textStart = markerAndText.index(after: closingBracket)
        let text = markerAndText[textStart...]
            .trimmingCharacters(in: .whitespaces)
        return (["x", "X"].contains(String(marker)), String(text))
    }

    // MARK: - Inline directives (`<path> :image`, `<path> :file`)

}
