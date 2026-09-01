import Foundation
import AppKit

extension MarkdownHTMLRenderer {
    static let directiveExpression = try? NSRegularExpression(
        pattern: #"^(.*\S)[\t ]+:(image|file)$"#
    )

    static func inlineDirective(in line: String) -> (path: String, kind: String)? {
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

    static func renderDirective(
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

    static func renderInlineImage(path: String) -> String {
        guard let loaded = QuilterLibrary.readData(at: path) else {
            return #"<div class="quilter-missing">Image not found in Library: \#(escapeHTML(path))</div>"#
        }
        let url = loaded.url
        let data = loaded.data
        let mime = imageMimeType(for: url.pathExtension)
        let base64 = data.base64EncodedString()
        return #"<figure class="quilter-image"><img src="data:\#(mime);base64,\#(base64)" alt="\#(escapeAttribute(path))"></figure>"#
    }

    static func renderEmbeddedFile(
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

    static func imageMimeType(for ext: String) -> String {
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

    static func renderInline(_ source: String) -> String {
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

    static func startsBlock(_ line: String, nextLine: String? = nil) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return basicBlockStart(line: line, trimmed: trimmed) || tableStarts(line: line, nextLine: nextLine)
    }

    private static func basicBlockStart(line: String, trimmed: String) -> Bool {
        [
            trimmed.isEmpty,
            fencePrefix(in: trimmed) != nil,
            heading(in: line) != nil,
            isHorizontalRule(trimmed),
            trimmed.hasPrefix(">"),
            unorderedItem(in: line) != nil,
            orderedItem(in: line) != nil,
        ].contains(true)
    }

    private static func tableStarts(line: String, nextLine: String?) -> Bool {
        guard tableCells(in: line) != nil, let cells = nextLine.flatMap(tableCells) else { return false }
        return cells.allSatisfy { tableAlignment(in: $0) != nil }
    }

    static func heading(in line: String) -> (level: Int, title: String)? {
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

    static func fencePrefix(in line: String) -> String? {
        if line.hasPrefix("```") { return "```" }
        if line.hasPrefix("~~~") { return "~~~" }
        return nil
    }

    static func unorderedItem(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > 2,
              ["-", "*", "+"].contains(String(trimmed.prefix(1))),
              trimmed.dropFirst().first?.isWhitespace == true else {
            return nil
        }
        return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    static func orderedItem(in line: String) -> String? {
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

    static func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3, let first = compact.first,
              ["-", "*", "_"].contains(String(first)) else {
            return false
        }
        return compact.allSatisfy { $0 == first }
    }

    static func escapeHTML(_ source: String) -> String {
        source
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    static func escapeAttribute(_ source: String) -> String {
        source.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    static func replace(
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
