import AppKit
import XCTest
@testable import Quilter

final class MarkdownCoreTests: XCTestCase {
    @MainActor
    func testParserExtractsHeadingsTagsAndCounts() {
        let markdown = """
        # First title ##
        Intro sentence. Another sentence!
        A #Tag and a #tag plus #second-tag.
        ## Second
        """

        let state = MarkdownParser.derivedState(in: markdown)

        XCTAssertEqual(state.headings.map(\.title), ["First title", "Second"])
        XCTAssertEqual(state.headings.map(\.level), [1, 2])
        XCTAssertEqual(state.tags, ["Tag", "second-tag"])
        XCTAssertEqual(state.sentenceCount, 5)
        XCTAssertEqual(state.wordCount, 15)
        XCTAssertEqual(MarkdownParser.sentenceCount(in: " \n\t"), 0)
        XCTAssertEqual(MarkdownParser.wordCount(in: " \n\t"), 0)
    }

    @MainActor
    func testDocumentItemTracksDerivedStateAndSaveState() async throws {
        let document = DocumentItem(untitledName: "Draft.md", text: "# Draft\nOne sentence.")
        XCTAssertEqual(document.filename, "Draft.md")
        XCTAssertEqual(document.summary, "Draft")
        XCTAssertEqual(document.readingTimeMinutes, 1)
        XCTAssertTrue(document.isDirty)
        XCTAssertEqual(document.directoryDisplayName, "Not Saved")

        document.markSaved(at: URL(fileURLWithPath: "/tmp/Draft.md"))
        XCTAssertFalse(document.isDirty)
        XCTAssertEqual(document.filename, "Draft.md")
        XCTAssertEqual(document.directoryDisplayName, "/tmp/")

        document.text = "## Updated\nOne two three."
        XCTAssertTrue(document.isDirty)
        try await Task.sleep(for: .milliseconds(260))
        XCTAssertEqual(document.summary, "Updated")
        XCTAssertEqual(document.tags, [])
        XCTAssertEqual(document.wordCount, 4)
        XCTAssertEqual(document.readingTimeMinutes, 1)
    }

    @MainActor
    func testPreferencesPersistEverySettingType() {
        let suiteName = "QuilterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let preferences = AppPreferences(defaults: defaults)

        preferences.editorFont = .quiltVier
        preferences.columnCharacterCount = 72
        preferences.highlightColor = .blue
        preferences.autosave = false
        preferences.focusScope = .sentence
        preferences.typewriterScrolling = true
        preferences.showsDocumentTracker = false
        preferences.highlightsNouns = true
        preferences.highlightsVerbs = true
        preferences.highlightsAdjectives = true
        preferences.highlightsAdverbs = true
        preferences.highlightsConjunctions = true
        preferences.checksCliches = true
        preferences.checksRedundancies = true
        preferences.checksFillers = true
        preferences.previewFont = .monospace
        preferences.centersPreviewHeaders = true
        preferences.highlightsPreviewCode = false
        preferences.rendersLaTeXMath = false
        preferences.rendersMermaidGraphs = true
        preferences.toolbarVisibility = .alwaysShown
        preferences.showsFilesInSidebar = false
        preferences.showsOutlineInSidebar = false
        preferences.showsHashtagsInSidebar = true

        let restored = AppPreferences(defaults: defaults)
        XCTAssertEqual(restored.editorFont, .quiltVier)
        XCTAssertEqual(restored.columnCharacterCount, 72)
        XCTAssertEqual(restored.highlightColor, .blue)
        XCTAssertFalse(restored.autosave)
        XCTAssertEqual(restored.focusScope, .sentence)
        XCTAssertTrue(restored.typewriterScrolling)
        XCTAssertFalse(restored.showsDocumentTracker)
        XCTAssertTrue(restored.highlightsNouns && restored.highlightsVerbs)
        XCTAssertTrue(restored.highlightsAdjectives && restored.highlightsAdverbs)
        XCTAssertTrue(restored.highlightsConjunctions)
        XCTAssertTrue(restored.checksCliches && restored.checksRedundancies && restored.checksFillers)
        XCTAssertEqual(restored.previewFont, .monospace)
        XCTAssertTrue(restored.centersPreviewHeaders)
        XCTAssertFalse(restored.highlightsPreviewCode && restored.rendersLaTeXMath)
        XCTAssertTrue(restored.rendersMermaidGraphs)
        XCTAssertEqual(restored.toolbarVisibility, .alwaysShown)
        XCTAssertFalse(restored.showsFilesInSidebar || restored.showsOutlineInSidebar)
        XCTAssertTrue(restored.showsHashtagsInSidebar)
    }

    @MainActor
    func testRendererCoversMarkdownBlockFamiliesAndOptions() {
        let defaults = UserDefaults(suiteName: "QuilterRendererTests.\(UUID().uuidString)")!
        let preferences = AppPreferences(defaults: defaults)
        preferences.centersPreviewHeaders = true
        preferences.highlightsPreviewCode = true
        preferences.rendersLaTeXMath = true
        preferences.rendersMermaidGraphs = true
        preferences.previewFont = .monospace

        let markdown = """
        # Heading
        Paragraph with **bold**, _italic_, ~~deleted~~, `code`, and [link](https://example.com).

        > quoted line
        > continued

        - unordered
        - second
        1. ordered
        2. second
        - [ ] pending
        - [x] done

        | A | B |
        | :--- | ---: |
        | one | two |

        ```swift
        let value = 1 < 2
        ```

        ```mermaid
        graph TD
        A --> B
        ```

        ---
        missing.png :image
        """

        let html = MarkdownHTMLRenderer.render(markdown, preferences: preferences)
        XCTAssertTrue(html.contains("<h1>Heading</h1>"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("class=\"task-list\""))
        XCTAssertTrue(html.contains("class=\"quilter-table-wrap\""))
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("class=\"mermaid\""))
        XCTAssertTrue(html.contains("Image not found in Library"))
        XCTAssertTrue(html.contains("text-align:left"))
        XCTAssertTrue(html.contains("text-align:right"))
        XCTAssertTrue(html.contains("text-align:center") == false)

        preferences.highlightsPreviewCode = false
        preferences.rendersLaTeXMath = false
        preferences.rendersMermaidGraphs = false
        preferences.centersPreviewHeaders = false
        let quietHTML = MarkdownHTMLRenderer.render("plain", preferences: preferences)
        XCTAssertFalse(quietHTML.contains("highlight.js"))
        XCTAssertFalse(quietHTML.contains("katex"))
        XCTAssertFalse(quietHTML.contains("mermaid.js"))
        XCTAssertFalse(quietHTML.contains("h1, h2, h3 { text-align: center; }"))
    }

    @MainActor
    func testMarkdownTokenHelpersCoverAcceptedAndRejectedForms() {
        XCTAssertEqual(MarkdownHTMLRenderer.renderInline("<&> \" **b** _i_ ~~d~~ `c` [x](https://example.com)"), "&lt;&amp;&gt; &quot; <strong>b</strong> <em>i</em> <del>d</del> <code>c</code> <a href=\"https://example.com\">x</a>")
        XCTAssertEqual(MarkdownHTMLRenderer.heading(in: "  ### Title ###")?.level, 3)
        XCTAssertNil(MarkdownHTMLRenderer.heading(in: "###No space"))
        XCTAssertEqual(MarkdownHTMLRenderer.fencePrefix(in: "````swift"), "```" )
        XCTAssertEqual(MarkdownHTMLRenderer.fencePrefix(in: "~~~"), "~~~")
        XCTAssertNil(MarkdownHTMLRenderer.fencePrefix(in: "plain"))
        XCTAssertEqual(MarkdownHTMLRenderer.unorderedItem(in: " * item "), "item")
        XCTAssertEqual(MarkdownHTMLRenderer.orderedItem(in: " 12. item"), "item")
        XCTAssertNil(MarkdownHTMLRenderer.orderedItem(in: "item"))
        XCTAssertTrue(MarkdownHTMLRenderer.isHorizontalRule("* * *"))
        XCTAssertFalse(MarkdownHTMLRenderer.isHorizontalRule("--"))
        XCTAssertEqual(MarkdownHTMLRenderer.escapeAttribute("a/b c.d_2-3"), "abcd_2-3")
        XCTAssertEqual(MarkdownHTMLRenderer.imageMimeType(for: "JPG"), "image/jpeg")
        XCTAssertEqual(MarkdownHTMLRenderer.imageMimeType(for: "unknown"), "application/octet-stream")
        XCTAssertEqual(MarkdownHTMLRenderer.inlineDirective(in: "assets/photo.png :image")?.kind, "image")
        XCTAssertNil(MarkdownHTMLRenderer.inlineDirective(in: " :image"))
        XCTAssertTrue(MarkdownHTMLRenderer.startsBlock("| A | B |", nextLine: "| --- | --- |"))
        XCTAssertFalse(MarkdownHTMLRenderer.startsBlock("paragraph"))
        XCTAssertEqual(MarkdownHTMLRenderer.tableCells(in: "| `a|b` | c |"), ["`a|b`", "c"])
        XCTAssertEqual(MarkdownHTMLRenderer.splitTableCells("a\\|b|`c|d`|e"), ["a\\|b", "`c|d`", "e"])
        XCTAssertEqual(MarkdownHTMLRenderer.tableAlignment(in: ":---"), "left")
        XCTAssertEqual(MarkdownHTMLRenderer.tableAlignment(in: "---:"), "right")
        XCTAssertEqual(MarkdownHTMLRenderer.tableAlignment(in: ":---:"), "center")
        XCTAssertEqual(MarkdownHTMLRenderer.tableAlignment(in: "---"), "")
        XCTAssertEqual(MarkdownHTMLRenderer.taskItem(in: "- [X] done")?.checked, true)
        XCTAssertEqual(MarkdownHTMLRenderer.taskItem(in: "- [ ] todo")?.text, "todo")
        XCTAssertNil(MarkdownHTMLRenderer.taskItem(in: "- [!] invalid"))
    }

    @MainActor
    func testModelAndThemeEnumerationsExposeStableValues() {
        XCTAssertEqual(EditorLayout.allCases, [.editorOnly, .split, .previewOnly])
        XCTAssertEqual(PreviewFontType.monospace.cssFamily, "'Lekton', ui-monospace, 'SFMono-Regular', Menlo, monospace")
        XCTAssertEqual(ToolbarVisibilityMode.allCases, [.alwaysHidden, .hover, .alwaysShown])
        XCTAssertEqual(FocusScope.allCases, [.paragraph, .sentence])
        XCTAssertEqual(MarkdownHighlightColor.allCases.count, 6)
        XCTAssertEqual(EditorStatusMetric.allCases.map(\.systemImage), [
            "text.line.first.and.arrowtriangle.forward", "textformat.abc", "clock"
        ])
        XCTAssertEqual(AppTheme.gridGutter, 16)
        XCTAssertEqual(AppTheme.gridContentInset, 32)
        XCTAssertEqual(AppTheme.toolbarControlSize, 38)
        XCTAssertEqual(AppTheme.fieldHeight, 36)
        XCTAssertEqual(AppTheme.TypographyRole.caption.size, 12)
        XCTAssertEqual(AppTheme.TypographyRole.micro.size, 9)
        XCTAssertEqual(AppState.isValidFilename("notes.md"), true)
        XCTAssertEqual(AppState.isValidFilename("bad/name.md"), false)
        XCTAssertEqual(AppState.isValidFilename("."), false)
        XCTAssertEqual(AppState.isSupportedDocument(URL(fileURLWithPath: "/tmp/notes.md")), true)
        XCTAssertEqual(AppState.isSupportedDocument(URL(fileURLWithPath: "/tmp/notes.txt")), true)
        XCTAssertEqual(AppState.isSupportedDocument(URL(fileURLWithPath: "/tmp/image.png")), false)
    }

    @MainActor
    func testMetadataModelsExposeEveryDisplayBranch() {
        for font in PreviewFontType.allCases {
            XCTAssertEqual(font.id, font)
            XCTAssertFalse(String(localized: font.title).isEmpty)
            XCTAssertFalse(font.cssFamily.isEmpty)
        }

        for color in MarkdownHighlightColor.allCases {
            XCTAssertEqual(color.id, color)
            XCTAssertFalse(String(localized: color.title).isEmpty)
            XCTAssertNotNil(color.nsColor)
        }

        for scope in FocusScope.allCases {
            XCTAssertEqual(scope.id, scope)
            XCTAssertFalse(String(localized: scope.title).isEmpty)
        }

        for mode in ToolbarVisibilityMode.allCases {
            XCTAssertEqual(mode.id, mode)
            XCTAssertFalse(String(localized: mode.title).isEmpty)
        }

        let error = AppError(title: "Error", message: "Message")
        XCTAssertFalse(error.id.uuidString.isEmpty)
        XCTAssertEqual(error.message, "Message")

        let target = EditorScrollTarget(range: NSRange(location: 2, length: 3))
        XCTAssertEqual(target.range, NSRange(location: 2, length: 3))
        XCTAssertFalse(target.id.uuidString.isEmpty)
    }
}
