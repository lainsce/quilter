import Foundation

enum CheatsheetEntry: String, CaseIterable, Identifiable {
    case heading1
    case heading2
    case heading3
    case bold
    case italic
    case strikethrough
    case inlineCode
    case link
    case blockquote
    case bullet
    case numbered
    case codeBlock
    case horizontalRule
    case image
    case tag
    case libraryImage
    case libraryFile

    var id: Self { self }

    var syntax: String {
        switch self {
        case .heading1: "# Heading 1"
        case .heading2: "## Heading 2"
        case .heading3: "### Heading 3"
        case .bold: "**bold**"
        case .italic: "_italic_"
        case .strikethrough: "~~strikethrough~~"
        case .inlineCode: "`inline code`"
        case .link: "[link](https://…)"
        case .blockquote: "> blockquote"
        case .bullet: "- bullet item"
        case .numbered: "1. numbered item"
        case .codeBlock: "```\ncode block\n```"
        case .horizontalRule: "---"
        case .image: "![alt](image.png)"
        case .tag: "#tag"
        case .libraryImage: "photo.png :image"
        case .libraryFile: "note.md :file"
        }
    }
}
