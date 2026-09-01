import AppKit
import SwiftUI
import XCTest
@testable import Quilter

@MainActor
final class QuilterViewConstructionTests: XCTestCase {
    private func makeState() -> (AppState, AppPreferences, DocumentItem) {
        let preferences = AppPreferences(
            defaults: UserDefaults(suiteName: "Quilter.ViewTests.\(UUID().uuidString)")!
        )
        let state = AppState(preferences: preferences)
        let document = DocumentItem(
            untitledName: "Draft.md",
            text: "# Draft\nA paragraph with #work."
        )
        state.openDocuments = [document]
        state.selectedDocumentID = document.id
        return (state, preferences, document)
    }

    func testConstructsCheatsheetAndContentViews() {
        let (state, preferences, document) = makeState()

        for entry in CheatsheetEntry.allCases {
            _ = CheatsheetEffectView(entry: entry).body
        }
        _ = CheatsheetHeader(closeAction: {}).body
        _ = CheatsheetView().body
        _ = ActiveDocumentTitle(appState: state).body
        _ = EditorStatusBadge(document: document).body
        _ = EmptyEditorView(openAction: {}).body
        _ = FocusModeExitButton(action: {}).body
        _ = LegalNoticesView().body
        _ = PrivacyPolicySection(title: "Local", systemImage: "lock", text: "Stored locally").body
        _ = PrivacyPolicyView().body
        _ = QuilterAboutView().body
        _ = ScrollEdgeTreatment(color: .blue, edge: .top, height: 30).body
        _ = ScrollEdgeTreatment(color: .blue, edge: .bottom, height: 30).body
        _ = SidebarEmptyFilesView(openAction: {}).body
        _ = SidebarSectionHeader(title: "Files").body
        _ = TagChip(tag: "work", isSelected: true, action: {}).body
        _ = TagChip(tag: "ideas", isSelected: false, action: {}).body
        _ = OutlineRow(
            heading: HeadingItem(title: "Draft", level: 2, textRange: NSRange(location: 0, length: 7)),
            action: {}
        ).body
        _ = OutlineView(document: document).body
        _ = OutlineView(document: nil).body
        _ = SidebarHashtagListView(appState: state).body
        _ = TagFilterView(appState: state).body

        _ = EditorSettingsView(preferences: preferences).body
        _ = PreviewSettingsView(preferences: preferences).body
        _ = LibrarySettingsView(appState: state, preferences: preferences).body
        _ = SettingsView(appState: state, preferences: preferences).body
        _ = RenameDocumentPopover(currentFilename: document.filename, renameAction: { _ in true }, cancelAction: {}).body
    }

    func testConstructsDocumentListsAndEditorSurfaces() {
        let (state, preferences, document) = makeState()
        let second = DocumentItem(untitledName: "Second.md", text: "## Second")
        state.openDocuments.append(second)

        _ = OpenDocumentRow(
            document: document,
            isSelected: true,
            isFirst: true,
            isLast: false,
            selectAction: {},
            closeAction: {},
            saveAndCloseAction: {}
        ).body
        _ = OpenDocumentRow(
            document: second,
            isSelected: false,
            isFirst: false,
            isLast: true,
            selectAction: {},
            closeAction: {},
            saveAndCloseAction: {}
        ).body
        _ = OpenDocumentsList(appState: state).body

        _ = MarkdownEditorView(document: document, appState: state, preferences: preferences).body
        _ = MarkdownPreviewView(document: document, preferences: preferences).body
        _ = MarkdownTextView(
            text: .constant(document.text),
            scrollTarget: nil,
            isFocusMode: false,
            preferences: preferences
        )
        _ = MarkdownPreviewWebView(
            markdown: document.text,
            preferences: preferences,
            columnLayout: MarkdownColumnLayout(
                availableWidth: 900,
                targetTextWidth: 600,
                markerGutter: 24
            )
        )
        _ = EditorPaneView(appState: state, preferences: preferences)
        _ = AppWindowView(appState: state, preferences: preferences).body
    }

    func testConstructsNuulControlsAndEnvironmentBoundViews() {
        let (state, preferences, _) = makeState()
        let chromeState = WindowChromeState()

        _ = NULFormRow("Setting", description: "Description") { Text("Value") }.body
        _ = NULMenuPicker(
            "Font",
            selection: .constant(EditorFontType.quiltMono),
            options: EditorFontType.allCases
        ) { Text($0.title) }.body
        _ = NULSegmentedPicker(
            selection: .constant(EditorLayout.split),
            options: EditorLayout.allCases
        ) { Text($0.rawValue) }.body
        _ = NULSidebarSurface().body
        _ = NULIcon(systemImage: "plus").body
        _ = Text("Field").modifier(NULFieldModifier())
        _ = Text("Toolbar").modifier(NULToolbarSurface(isVisible: true))
        _ = Text("Toolbar").modifier(NULToolbarSurface(isVisible: false))
        _ = Text("Window").modifier(NULWindowActivityAppearance())
        _ = NULToggleStyle()
        _ = NULButtonStyle(kind: .primary)
        _ = NULButtonStyle(kind: .neutral)
        _ = NULButtonStyle(kind: .quiet)
        _ = NULToolbarButtonStyle(accented: true)
        _ = QuilterSidebarRowButtonStyle()
        let onToggle = Toggle("Toggle", isOn: .constant(true)).toggleStyle(NULToggleStyle())
        let offToggle = Toggle("Toggle", isOn: .constant(false)).toggleStyle(NULToggleStyle())
        _ = (onToggle, offToggle)
        let primaryButton = Button(action: {}) { Text("Primary") }
            .buttonStyle(NULButtonStyle(kind: .primary))
        let neutralButton = Button(action: {}) { Text("Neutral") }
            .buttonStyle(NULButtonStyle(kind: .neutral))
        let quietButton = Button(action: {}) { Text("Quiet") }
            .buttonStyle(NULButtonStyle(kind: .quiet))
        let toolbarButton = Button(action: {}) { Text("Toolbar") }
            .buttonStyle(NULToolbarButtonStyle(accented: true))
        _ = (primaryButton, neutralButton, quietButton, toolbarButton)

        _ = EditorActionsMenu(appState: state).body
        _ = EditorHighlightsMenu(appState: state, preferences: preferences)
        _ = OpenControl(appState: state)
        _ = SidebarView(appState: state, preferences: preferences)
        _ = AppWindowView(appState: state, preferences: preferences)
        _ = EditorPaneView(appState: state, preferences: preferences)
        _ = ActiveDocumentTitle(appState: state)
        _ = LibrarySettingsView(appState: state, preferences: preferences)
        _ = EmptyEditorView(openAction: {})
        _ = QuilterAboutView()
        _ = PrivacyPolicyView()

        XCTAssertTrue(chromeState.isVisible)
    }

    func testRendersNuulControlsThroughSwiftUI() {
        func assertRenders<Control: View>(_ control: Control) {
            let renderer = ImageRenderer(content: control.environment(\.colorScheme, .dark))
            renderer.scale = 1
            XCTAssertNotNil(renderer.nsImage)
        }

        assertRenders(Button(action: {}) { Text("Primary") }.buttonStyle(NULButtonStyle(kind: .primary)))
        assertRenders(Button(action: {}) { Text("Neutral") }.buttonStyle(NULButtonStyle(kind: .neutral)))
        assertRenders(Button(action: {}) { Text("Quiet") }.buttonStyle(NULButtonStyle(kind: .quiet)))
        assertRenders(Button(action: {}) { Text("Disabled") }.buttonStyle(NULButtonStyle(kind: .primary)).disabled(true))
        assertRenders(Toggle("Toggle", isOn: .constant(true)).toggleStyle(NULToggleStyle()))
        assertRenders(Toggle("Toggle", isOn: .constant(false)).toggleStyle(NULToggleStyle()))
        assertRenders(TextField("Field", text: .constant("Value")).textFieldStyle(NULTextFieldStyle()))
        assertRenders(Button(action: {}) { Image(systemName: "plus") }
            .buttonStyle(NULToolbarButtonStyle(showsSurface: true, accented: true)))
        assertRenders(NULSegmentedPicker(selection: .constant(EditorLayout.split), options: EditorLayout.allCases) { Text($0.rawValue) })
        assertRenders(NULFormRow("Field") { Text("Value") })
        assertRenders(NULIcon(systemImage: "plus"))
    }

    func testModelDisplayValuesAndLibraryHelpers() {
        let (_, preferences, document) = makeState()
        XCTAssertEqual(CheatsheetEntry.allCases.count, 17)
        for entry in CheatsheetEntry.allCases {
            XCTAssertFalse(entry.syntax.isEmpty)
            XCTAssertEqual(entry.id, entry)
        }
        XCTAssertEqual(EditorFontType.allCases.count, 3)
        XCTAssertEqual(EditorFontType.quiltMono.font(ofSize: 14).pointSize, 14)
        XCTAssertFalse(EditorFontType.quiltMono.boldTextAttributes(ofSize: 14).isEmpty)
        _ = EditorStatusMetric.sentences.displayText(for: document)
        _ = EditorStatusMetric.words.displayText(for: document)
        _ = EditorStatusMetric.readingTime.displayText(for: document)
        XCTAssertEqual(PreviewFontType.allCases.count, 3)
        XCTAssertEqual(ToolbarVisibilityMode.allCases.count, 3)
        XCTAssertEqual(FocusScope.allCases.count, 2)
        for mode in ToolbarVisibilityMode.allCases { _ = mode.title }
        for scope in FocusScope.allCases { _ = scope.title }
        _ = EditorScrollTarget(range: NSRange(location: 0, length: 1))
        _ = AppError(title: "Error", message: "Message")
        XCTAssertEqual(AppTheme.TypographyRole.body.size, 14)
        XCTAssertEqual(AppTheme.TypographyRole.viewTitle.size, 28)
        XCTAssertEqual(QuilterLibrary.folderName, "Quilter")
        XCTAssertFalse(QuilterLibrary.locationDescription.isEmpty)
        XCTAssertEqual(preferences.columnCharacterCount, 64)
    }
}
