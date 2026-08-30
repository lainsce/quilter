import Foundation
import AppKit

private struct PreviewThemeCSS {
    let rootDeclarations: String
    let appearanceOverrides: String
}

enum MarkdownHTMLRenderer {
    static func render(
        _ markdown: String,
        preferences: AppPreferences
    ) -> String {
        let body = renderBlocks(
            markdown,
            rendersMermaid: preferences.rendersMermaidGraphs,
            visited: []
        )
        let centeredHeaders = preferences.centersPreviewHeaders
            ? "h1, h2, h3 { text-align: center; }"
            : ""
        let previewTheme = previewThemeCSS()

        // Match the preview's text selection to the app's themed accent.
        let selectionColor = AppTheme.accentCSSColor(alpha: 0.3)

        let codeResources = preferences.highlightsPreviewCode
            ? """
              <link rel="stylesheet" href="highlight.js/styles/default.min.css" media="(prefers-color-scheme: light)">
              <link rel="stylesheet" href="highlight.js/styles/dark.min.css" media="(prefers-color-scheme: dark)">
              <script src="highlight.js/lib/highlight.min.js"></script>
              """
            : ""
        let latexResources = preferences.rendersLaTeXMath
            ? """
              <link rel="stylesheet" href="katex/katex.css">
              <script src="katex/katex.js"></script>
              <script src="katex/render.js"></script>
              """
            : ""
        let mermaidResources = preferences.rendersMermaidGraphs
            ? #"<script src="mermaid/mermaid.js"></script>"#
            : ""

        var readyScripts: [String] = []
        if preferences.highlightsPreviewCode {
            readyScripts.append("hljs.highlightAll();")
        }
        if preferences.rendersLaTeXMath {
            readyScripts.append("renderMathInElement(document.body);")
        }
        if preferences.rendersMermaidGraphs {
            let mermaidTheme = "window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'"
            readyScripts.append(
                "mermaid.initialize({ startOnLoad: true, theme: \(mermaidTheme) });"
            )
        }

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline' quilter-preview:; script-src 'unsafe-inline' quilter-preview:; img-src data: quilter-preview:; font-src data: quilter-preview:; connect-src 'none'; frame-ancestors 'none';">
          <style>
            :root {
              color-scheme: light dark;
              \(previewTheme.rootDeclarations)
              /* Updated in place by MarkdownPreviewWebView from the shared
                 AppKit column metrics whenever the pane is resized. */
              --quilter-preview-max-width: min(820px, calc(\(preferences.columnCharacterCount)ch + 128px));
              --quilter-preview-leading-inset: 64px;
              --quilter-preview-trailing-inset: 64px;
            }
            \(previewTheme.appearanceOverrides)
            html { background: var(--quilter-preview-background); }
            body {
              box-sizing: border-box;
              width: 100%;
              /*
               These variables are calculated from the same column metrics as
               the NSTextView. Keep width: 100% so the surface remains fluid as
               the split divider moves.
               */
              max-width: var(--quilter-preview-max-width);
              margin: 0 auto;
              padding: 56px var(--quilter-preview-trailing-inset) 96px var(--quilter-preview-leading-inset);
              color: var(--quilter-preview-foreground);
              background: var(--quilter-preview-background);
              font-family: \(preferences.previewFont.cssFamily);
              font-size: 16px;
              line-height: 28px;
              letter-spacing: 0.005em;
              overflow-wrap: anywhere;
            }
            h1, h2, h3, h4 {
              margin: 0;
              line-height: 28px;
              font-weight: 700;
              letter-spacing: -0.012em;
            }
            h1 { font-size: 26px; }
            h2 { font-size: 22px; }
            h3 { font-size: 19px; }
            h4 { font-size: 17px; }
            p, ul, ol, blockquote, pre { margin: 0; }
            .quilter-blank-line {
              height: 1.75rem;
              width: 100%;
            }
            .quilter-table-wrap {
              max-width: 100%;
              margin: 1.1em 0;
              overflow-x: auto;
              overscroll-behavior-x: contain;
            }
            table {
              width: max-content;
              min-width: 100%;
              border-collapse: collapse;
              table-layout: auto;
            }
            th, td {
              padding: 0.35em 0.6em;
              border: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 18%, transparent);
              vertical-align: top;
              text-align: left;
            }
            th {
              white-space: nowrap;
              font-weight: 600;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 6%, var(--quilter-preview-background));
            }
            .task-list {
              list-style: none;
              padding-left: 0;
            }
            .task-list li {
              display: flex;
              align-items: flex-start;
              gap: 0.55em;
            }
            .task-list input {
              flex: 0 0 auto;
              width: 1em;
              height: 1em;
              margin: 0.36em 0 0;
              accent-color: var(--quilter-preview-accent);
            }
            blockquote {
              margin-left: 0;
              padding-left: 1em;
              border-left: 2px solid color-mix(in srgb, var(--quilter-preview-foreground) 28%, transparent);
              color: color-mix(in srgb, var(--quilter-preview-foreground) 68%, transparent);
            }
            pre {
              padding: 0.85em 1em;
              border: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 18%, transparent);
              border-radius: 4px;
              overflow: auto;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 4%, var(--quilter-preview-background));
            }
            code {
              font-family: ui-monospace, 'SFMono-Regular', Menlo, monospace;
              font-size: 0.9em;
            }
            :not(pre) > code {
              padding: 0.12em 0.32em;
              border-radius: 3px;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 7%, var(--quilter-preview-background));
            }
            a { color: var(--quilter-preview-accent); }
            .hljs, .hljs * {
              color: var(--quilter-preview-foreground) !important;
              background: transparent !important;
            }
            .hljs-keyword, .hljs-title, .hljs-built_in, .hljs-type,
            .hljs-name, .hljs-attribute, .hljs-selector-tag {
              font-weight: 700;
            }
            ::selection { background: \(selectionColor); }
            hr {
              border: 0;
              border-top: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 24%, transparent);
              margin: 1.5em 0;
            }
            img, svg { max-width: 100%; height: auto; }
            .mermaid { display: flex; justify-content: center; margin: 1.5em 0; }
            .quilter-image { margin: 1.5em 0; text-align: center; }
            .quilter-image img { display: inline-block; max-width: 100%; border-radius: 4px; }
            .quilter-embed {
              margin: 1.5em 0;
              padding: 0.2em 1em;
              border-left: 2px solid color-mix(in srgb, var(--quilter-preview-foreground) 28%, transparent);
            }
            .quilter-missing {
              margin: 1.5em 0;
              padding: 0.55em 0.85em;
              border-radius: 4px;
              font-style: italic;
              color: color-mix(in srgb, var(--quilter-preview-foreground) 55%, transparent);
              background: color-mix(in srgb, var(--quilter-preview-foreground) 6%, var(--quilter-preview-background));
            }
            \(centeredHeaders)
          </style>
          \(codeResources)
          \(latexResources)
          \(mermaidResources)
        </head>
        <body>
          \(body)
          <script>
            document.addEventListener('DOMContentLoaded', function () {
              \(readyScripts.joined(separator: "\n"))
            });
          </script>
        </body>
        </html>
        """
    }

    private static func previewThemeCSS() -> PreviewThemeCSS {
        // Resolve both branches through the same preview tokens used by the
        // native preview surface. WebKit follows the host appearance through
        // the media query below, while the actual RGB values remain owned by
        // AppTheme.
        let lightAppearance = NSAppearance(named: .aqua)!
        let darkAppearance = NSAppearance(named: .darkAqua)!
        let lightBackground = cssColor(
            AppTheme.previewSurfaceColor(for: lightAppearance)
        )
        let lightForeground = cssColor(
            AppTheme.previewTextColor(for: lightAppearance)
        )
        let darkBackground = cssColor(
            AppTheme.previewSurfaceColor(for: darkAppearance)
        )
        let darkForeground = cssColor(
            AppTheme.previewTextColor(for: darkAppearance)
        )
        let accent = AppTheme.accentCSSColor()
        let rootDeclarations = """
          --quilter-preview-background: \(lightBackground);
          --quilter-preview-foreground: \(lightForeground);
          --quilter-preview-accent: \(accent);
        """
        return PreviewThemeCSS(
            rootDeclarations: rootDeclarations,
            appearanceOverrides: """
            @media (prefers-color-scheme: dark) {
              :root {
                --quilter-preview-background: \(darkBackground);
                --quilter-preview-foreground: \(darkForeground);
              }
            }
            """
        )
    }

    private static func cssColor(_ color: NSColor) -> String {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        let red = Int((srgb.redComponent * 255).rounded())
        let green = Int((srgb.greenComponent * 255).rounded())
        let blue = Int((srgb.blueComponent * 255).rounded())
        return "rgb(\(red), \(green), \(blue))"
    }

    private static func renderBlocks(
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
                // Keep authored blank rows in the preview. The source editor
                // gives each row the shared 28-point line height, so emitting
                // one matching spacer keeps headings and body text in step
                // across the split view without inventing block margins.
                let hasFollowingContent = lines[(index + 1)...].contains {
                    !$0.trimmingCharacters(in: .whitespaces).isEmpty
                }
                if !html.isEmpty && hasFollowingContent {
                    html.append("<div class=\"quilter-blank-line\" aria-hidden=\"true\"></div>")
                }
                index += 1
                continue
            }

            if let fence = fencePrefix(in: trimmed) {
                let language = String(trimmed.dropFirst(fence.count))
                    .trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                index += 1
                while index < lines.count,
                      !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                    codeLines.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 }

                let code = escapeHTML(codeLines.joined(separator: "\n"))
                if rendersMermaid, language.lowercased() == "mermaid" {
                    html.append("<div class=\"mermaid\">\(code)</div>")
                } else {
                    let languageClass = language.isEmpty
                        ? ""
                        : " class=\"language-\(escapeAttribute(language))\""
                    html.append("<pre><code\(languageClass)>\(code)</code></pre>")
                }
                continue
            }

            if let directive = inlineDirective(in: trimmed) {
                html.append(
                    renderDirective(
                        directive,
                        rendersMermaid: rendersMermaid,
                        visited: visited
                    )
                )
                index += 1
                continue
            }

            if let table = tableBlock(in: lines, startingAt: index) {
                html.append(renderTable(table))
                index = table.nextIndex
                continue
            }

            if let heading = heading(in: line) {
                html.append(
                    "<h\(heading.level)>\(renderInline(heading.title))</h\(heading.level)>"
                )
                index += 1
                continue
            }

            if isHorizontalRule(trimmed) {
                html.append("<hr>")
                index += 1
                continue
            }

            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while index < lines.count {
                    let quoteLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard quoteLine.hasPrefix(">") else { break }
                    quoteLines.append(
                        String(quoteLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                    )
                    index += 1
                }
                html.append("<blockquote>\(renderInline(quoteLines.joined(separator: " ")))</blockquote>")
                continue
            }

            if taskItem(in: line) != nil {
                var items: [String] = []
                while index < lines.count, let task = taskItem(in: lines[index]) {
                    let checkedAttribute = task.checked ? " checked" : ""
                    let label = renderInline(task.text)
                    items.append(
                        "<li><input type=\"checkbox\" disabled\(checkedAttribute) "
                            + "aria-label=\"\(task.checked ? "Checked" : "Unchecked")\">"
                            + "<span>\(label)</span></li>"
                    )
                    index += 1
                }
                html.append("<ul class=\"task-list\">\(items.joined())</ul>")
                continue
            }

            if unorderedItem(in: line) != nil {
                var items: [String] = []
                while index < lines.count, let item = unorderedItem(in: lines[index]) {
                    items.append("<li>\(renderInline(item))</li>")
                    index += 1
                }
                html.append("<ul>\(items.joined())</ul>")
                continue
            }

            if orderedItem(in: line) != nil {
                var items: [String] = []
                while index < lines.count, let item = orderedItem(in: lines[index]) {
                    items.append("<li>\(renderInline(item))</li>")
                    index += 1
                }
                html.append("<ol>\(items.joined())</ol>")
                continue
            }

            var paragraphLines = [trimmed]
            index += 1
            while index < lines.count,
                  !startsBlock(
                      lines[index],
                      nextLine: index + 1 < lines.count ? lines[index + 1] : nil
                  ) {
                let continuation = lines[index].trimmingCharacters(in: .whitespaces)
                guard !continuation.isEmpty else { break }
                paragraphLines.append(continuation)
                index += 1
            }
            html.append("<p>\(renderInline(paragraphLines.joined(separator: " ")))</p>")
        }

        return html.joined(separator: "\n")
    }

    private static func tableBlock(
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

    private static func renderTable(
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

    private static func renderTableCell(
        _ source: String,
        tag: String,
        alignment: String
    ) -> String {
        let style = alignment.isEmpty ? "" : " style=\"text-align:\(alignment)\""
        let cell = source.replacingOccurrences(of: "\\|", with: "|")
        return "<\(tag)\(style)>\(renderInline(cell))</\(tag)>"
    }

    private static func tableCells(in line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return nil }

        var content = trimmed
        if content.first == "|" { content.removeFirst() }
        if content.last == "|" { content.removeLast() }

        let cells = splitTableCells(content).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        return cells.count >= 2 ? cells : nil
    }

    private static func splitTableCells(_ content: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var isEscaped = false
        var isInsideCodeSpan = false

        for character in content {
            if isEscaped {
                current.append(character)
                isEscaped = false
                continue
            }
            if character == "\\" {
                current.append(character)
                isEscaped = true
                continue
            }
            if character == "`" {
                isInsideCodeSpan.toggle()
                current.append(character)
                continue
            }
            if character == "|" && !isInsideCodeSpan {
                cells.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        cells.append(current)
        return cells
    }

    private static func tableAlignment(in cell: String) -> String? {
        var token = cell.trimmingCharacters(in: .whitespaces)
        guard token.count >= 3 else { return nil }

        let isLeftAligned = token.first == ":"
        let isRightAligned = token.last == ":"
        if isLeftAligned { token.removeFirst() }
        if isRightAligned { token.removeLast() }

        guard token.count >= 3, token.allSatisfy({ $0 == "-" }) else {
            return nil
        }
        if isLeftAligned && isRightAligned { return "center" }
        if isRightAligned { return "right" }
        return isLeftAligned ? "left" : ""
    }

    private static func taskItem(in line: String) -> (checked: Bool, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(
            maxSplits: 1,
            omittingEmptySubsequences: true,
            whereSeparator: { $0.isWhitespace }
        )
        guard parts.count == 2,
              ["-", "*", "+"].contains(String(parts[0])) else {
            return nil
        }

        let markerAndText = parts[1]
        guard markerAndText.first == "[",
              let closingBracket = markerAndText.firstIndex(of: "]") else {
            return nil
        }

        let markerStart = markerAndText.index(after: markerAndText.startIndex)
        let marker = markerAndText[markerStart..<closingBracket]
        guard marker.isEmpty || marker == " " || marker == "x" || marker == "X" else {
            return nil
        }

        let textStart = markerAndText.index(after: closingBracket)
        let text = markerAndText[textStart...]
            .trimmingCharacters(in: .whitespaces)
        return (marker == "x" || marker == "X", String(text))
    }

    // MARK: - Inline directives (`<path> :image`, `<path> :file`)

    private static let directiveExpression = try? NSRegularExpression(
        pattern: #"^(.*\S)[\t ]+:(image|file)$"#
    )

    private static func inlineDirective(in line: String) -> (path: String, kind: String)? {
        guard let directiveExpression else { return nil }
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let match = directiveExpression.firstMatch(in: line, range: range),
              match.numberOfRanges == 3 else {
            return nil
        }
        let source = line as NSString
        let path = source.substring(with: match.range(at: 1))
            .trimmingCharacters(in: .whitespaces)
        let kind = source.substring(with: match.range(at: 2))
        return path.isEmpty ? nil : (path, kind)
    }

    private static func renderDirective(
        _ directive: (path: String, kind: String),
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> String {
        switch directive.kind {
        case "image":
            return renderInlineImage(path: directive.path)
        case "file":
            return renderEmbeddedFile(
                path: directive.path,
                rendersMermaid: rendersMermaid,
                visited: visited
            )
        default:
            return ""
        }
    }

    private static func renderInlineImage(path: String) -> String {
        guard let loaded = QuilterLibrary.readData(at: path) else {
            return #"<div class="quilter-missing">Image not found in Library: \#(escapeHTML(path))</div>"#
        }
        let url = loaded.url
        let data = loaded.data
        let mime = imageMimeType(for: url.pathExtension)
        let base64 = data.base64EncodedString()
        return #"<figure class="quilter-image"><img src="data:\#(mime);base64,\#(base64)" alt="\#(escapeAttribute(path))"></figure>"#
    }

    private static func renderEmbeddedFile(
        path: String,
        rendersMermaid: Bool,
        visited: Set<String>
    ) -> String {
        guard let loaded = QuilterLibrary.readText(at: path) else {
            return #"<div class="quilter-missing">File not found in Library: \#(escapeHTML(path))</div>"#
        }
        let url = loaded.url
        let key = url.standardizedFileURL.path
        guard !visited.contains(key) else {
            return #"<div class="quilter-missing">Skipped recursive embed: \#(escapeHTML(path))</div>"#
        }
        var nestedVisited = visited
        nestedVisited.insert(key)
        let inner = renderBlocks(
            loaded.text,
            rendersMermaid: rendersMermaid,
            visited: nestedVisited
        )
        return #"<div class="quilter-embed">\#(inner)</div>"#
    }

    private static func imageMimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "bmp": return "image/bmp"
        case "tiff", "tif": return "image/tiff"
        default: return "application/octet-stream"
        }
    }

    private static func renderInline(_ source: String) -> String {
        var output = escapeHTML(source)
        output = replace(#"`([^`]+)`"#, in: output, with: "<code>$1</code>")
        output = replace(#"(?<!\*)\*\*([^\n]+?)\*\*(?!\*)"#, in: output, with: "<strong>$1</strong>")
        output = replace(#"(?<!_)_([^_\n]+?)_(?!_)"#, in: output, with: "<em>$1</em>")
        output = replace(#"~~([^~\n]+?)~~"#, in: output, with: "<del>$1</del>")
        output = replace(
            #"\[([^\]]+)\]\((https?://[^\s\)]+)\)"#,
            in: output,
            with: "<a href=\"$2\">$1</a>"
        )
        return output
    }

    private static func startsBlock(_ line: String, nextLine: String? = nil) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty
            || fencePrefix(in: trimmed) != nil
            || heading(in: line) != nil
            || isHorizontalRule(trimmed)
            || trimmed.hasPrefix(">")
            || unorderedItem(in: line) != nil
            || orderedItem(in: line) != nil
            || (tableCells(in: line) != nil
                && nextLine.flatMap(tableCells).map { cells in
                    cells.allSatisfy { tableAlignment(in: $0) != nil }
                } == true)
    }

    private static func heading(in line: String) -> (level: Int, title: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let hashes = trimmed.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count),
              trimmed.dropFirst(hashes.count).first?.isWhitespace == true else {
            return nil
        }
        return (
            hashes.count,
            String(trimmed.dropFirst(hashes.count)).trimmingCharacters(in: .whitespaces)
        )
    }

    private static func fencePrefix(in line: String) -> String? {
        if line.hasPrefix("```") { return "```" }
        if line.hasPrefix("~~~") { return "~~~" }
        return nil
    }

    private static func unorderedItem(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > 2,
              ["-", "*", "+"].contains(String(trimmed.prefix(1))),
              trimmed.dropFirst().first?.isWhitespace == true else {
            return nil
        }
        return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    private static func orderedItem(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let match = try? NSRegularExpression(pattern: #"^\d+\.\s+(.+)$"#)
            .firstMatch(
                in: trimmed,
                range: NSRange(location: 0, length: (trimmed as NSString).length)
            ),
              match.numberOfRanges > 1 else {
            return nil
        }
        return (trimmed as NSString).substring(with: match.range(at: 1))
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3, let first = compact.first,
              ["-", "*", "_"].contains(String(first)) else {
            return false
        }
        return compact.allSatisfy { $0 == first }
    }

    private static func escapeHTML(_ source: String) -> String {
        source
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func escapeAttribute(_ source: String) -> String {
        source.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    private static func replace(
        _ pattern: String,
        in source: String,
        with template: String
    ) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return source }
        let range = NSRange(location: 0, length: (source as NSString).length)
        return expression.stringByReplacingMatches(
            in: source,
            range: range,
            withTemplate: template
        )
    }
}
