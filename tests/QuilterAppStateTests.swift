import AppKit
import XCTest
@testable import Quilter

@MainActor
final class QuilterAppStateTests: XCTestCase {
    private let stateDefaultsKeys = [
        AppState.DefaultsKey.sidebarVisible,
        AppState.DefaultsKey.recentFiles,
        AppState.DefaultsKey.recentFileBookmarks,
        AppState.DefaultsKey.openDocumentBookmarks,
        AppState.DefaultsKey.selectedDocumentPath,
        AppState.DefaultsKey.editorLayout
    ]

    private func withIsolatedState<T>(_ body: (AppState, AppPreferences) throws -> T) rethrows -> T {
        let defaults = UserDefaults.standard
        var saved: [String: NSObject] = [:]
        for key in stateDefaultsKeys {
            if let value = defaults.object(forKey: key) as? NSObject {
                saved[key] = value
            }
            defaults.removeObject(forKey: key)
        }
        defer {
            for key in stateDefaultsKeys { defaults.removeObject(forKey: key) }
            for (key, value) in saved { defaults.set(value, forKey: key) }
        }

        let preferences = AppPreferences(
            defaults: UserDefaults(suiteName: "Quilter.StateTests.\(UUID().uuidString)")!
        )
        return try body(AppState(preferences: preferences), preferences)
    }

    func testFilteringFocusAndDocumentNavigation() {
        withIsolatedState { state, _ in
            let first = DocumentItem(untitledName: "First.md", text: "# First\n#Work")
            let second = DocumentItem(untitledName: "Second.md", text: "## Second\n#ideas")
            state.openDocuments = [first, second]
            state.selectedDocumentID = first.id

            XCTAssertEqual(state.allTags, ["ideas", "Work"])
            XCTAssertTrue(state.canCycleDocuments)
            state.toggleTagFilter("work")
            XCTAssertEqual(state.selectedTag, "work")
            XCTAssertEqual(state.filteredDocuments.map(\.id), [first.id])
            state.toggleTagFilter("WORK")
            XCTAssertNil(state.selectedTag)

            state.selectNextDocument()
            XCTAssertEqual(state.selectedDocumentID, second.id)
            state.selectPreviousDocument()
            XCTAssertEqual(state.selectedDocumentID, first.id)
            state.toggleFocusMode()
            XCTAssertTrue(state.isFocusMode)
            XCTAssertEqual(state.editorLayout, .editorOnly)
            state.setEditorLayout(.split)
            XCTAssertEqual(state.editorLayout, .split)
            state.cycleEditorLayout()
            XCTAssertEqual(state.editorLayout, .previewOnly)
            state.exitFocusMode()
            XCTAssertFalse(state.isFocusMode)

            state.newDocument()
            XCTAssertEqual(state.openDocuments.map(\.filename), ["First.md", "Second.md", "Untitled.md"])
            XCTAssertEqual(state.selectedDocument?.filename, "Untitled.md")
        }
    }

    func testOpenSaveRenameAndCloseLifecycle() throws {
        try withIsolatedState { state, _ in
            let root = FileManager.default.temporaryDirectory
                .appending(path: "QuilterStateTests-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let source = root.appending(path: "source.md")
            try "# Source\nBody".write(to: source, atomically: true, encoding: .utf8)
            XCTAssertTrue(state.open(urls: [source]))
            XCTAssertEqual(state.openDocuments.count, 1)
            XCTAssertTrue(state.open(urls: [source]))
            XCTAssertEqual(state.openDocuments.count, 1)
            XCTAssertTrue(state.recentFileURLs.contains(source.standardizedFileURL))

            guard let document = state.selectedDocument else {
                return XCTFail("Expected opened document")
            }
            document.text = "# Updated\nChanged"
            XCTAssertTrue(state.save(document))
            XCTAssertFalse(document.isDirty)
            XCTAssertEqual(try String(contentsOf: source, encoding: .utf8), "# Updated\nChanged")

            XCTAssertFalse(state.renameSelectedDocument(to: "bad/name.md"))
            XCTAssertNotNil(state.presentedError)
            XCTAssertTrue(state.renameSelectedDocument(to: "renamed.md"))
            let renamed = root.appending(path: "renamed.md")
            XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
            XCTAssertEqual(document.filename, "renamed.md")

            let unsupported = root.appending(path: "image.png")
            try Data([0x01, 0x02]).write(to: unsupported)
            XCTAssertFalse(state.open(urls: [unsupported]))
            XCTAssertEqual(state.presentedError?.message, "Choose a Markdown or plain-text file.")
            state.presentedError = nil

            state.closeSelectedIfClean()
            XCTAssertTrue(state.openDocuments.isEmpty)
            state.selectDocument(offset: 1)
            XCTAssertNil(state.selectedDocumentID)
            state.clearRecentFiles()
            XCTAssertTrue(state.recentFileURLs.isEmpty)
        }
    }

    func testValidationSecurityScopeAndLibraryGuards() {
        withIsolatedState { state, _ in
            XCTAssertTrue(AppState.isValidFilename("draft.md"))
            XCTAssertFalse(AppState.isValidFilename(""))
            XCTAssertFalse(AppState.isValidFilename("."))
            XCTAssertFalse(AppState.isValidFilename("../draft.md"))
            XCTAssertTrue(AppState.isSupportedDocument(URL(filePath: "/tmp/draft.markdown")))
            XCTAssertTrue(AppState.isSupportedDocument(URL(filePath: "/tmp/draft.txt")))
            XCTAssertFalse(AppState.isSupportedDocument(URL(filePath: "/tmp/photo.png")))
            XCTAssertFalse(AppState.isSupportedDocument(URL(string: "https://example.com")!))

            let value = state.withSecurityScope(URL(filePath: "/tmp")) { "ok" }
            XCTAssertEqual(value, "ok")
            XCTAssertNil(QuilterLibrary.readText(at: "../../outside.txt"))
            XCTAssertNil(QuilterLibrary.readData(at: ""))
        }
    }
}
