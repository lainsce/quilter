import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
extension AppState {
    func toggleFocusMode() {
        isFocusMode.toggle()
    }

    func setEditorLayout(_ layout: EditorLayout) {
        guard selectedDocument != nil else { return }
        isFocusMode = false
        editorLayout = layout
    }

    func cycleEditorLayout() {
        guard selectedDocument != nil else { return }
        isFocusMode = false
        editorLayout = nextLayout(after: editorLayout)
    }

    private func nextLayout(after layout: EditorLayout) -> EditorLayout {
        switch layout {
        case .editorOnly: .split
        case .split: .previewOnly
        case .previewOnly: .editorOnly
        }
    }

    func exitFocusMode() {
        isFocusMode = false
    }

    func select(_ document: DocumentItem) {
        selectedDocumentID = document.id
        persistWorkspaceState()
    }

    func selectNextDocument() {
        selectDocument(offset: 1)
    }

    func selectPreviousDocument() {
        selectDocument(offset: -1)
    }

    @discardableResult
    func renameSelectedDocument(to proposedFilename: String) -> Bool {
        guard let selectedDocument else { return false }
        let filename = proposedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidFilename(filename) else {
            presentedError = AppError(
                title: "Invalid Filename",
                message: String(localized: "Enter a filename without slashes or colons.")
            )
            return false
        }
        return rename(selectedDocument, to: filename)
    }

    @discardableResult
    private func rename(_ document: DocumentItem, to filename: String) -> Bool {
        guard filename != document.filename else { return true }
        guard let oldURL = document.fileURL else {
            document.renameUntitledDocument(to: filename)
            return true
        }
        return renameFile(document, from: oldURL, to: filename)
    }

    private func renameFile(_ document: DocumentItem, from oldURL: URL, to filename: String) -> Bool {
        let newURL = oldURL.deletingLastPathComponent().appending(path: filename)
        let isCaseOnlyRename = oldURL.path.caseInsensitiveCompare(newURL.path) == .orderedSame
        guard isCaseOnlyRename || !FileManager.default.fileExists(atPath: newURL.path) else {
            presentedError = AppError(
                title: "A File Already Uses That Name",
                message: String(localized: "Choose a different filename.")
            )
            return false
        }
        do {
            try withSecurityScope(oldURL) {
                try FileManager.default.moveItem(at: oldURL, to: newURL)
            }
            document.updateFileURL(newURL)
            recentFileURLs.removeAll { $0.standardizedFileURL == oldURL.standardizedFileURL }
            addRecentFile(newURL)
            persistWorkspaceState()
            return true
        } catch {
            presentedError = AppError(
                title: "Couldn't Rename \(document.filename)",
                message: error.localizedDescription
            )
            return false
        }
    }

    func newDocument() {
        let existingNames = Set(openDocuments.map(\.filename))
        var candidate = "Untitled.md"
        var suffix = 2

        while existingNames.contains(candidate) {
            candidate = "Untitled \(suffix).md"
            suffix += 1
        }

        let document = DocumentItem(untitledName: candidate)
        openDocuments.append(document)
        selectedDocumentID = document.id
        persistWorkspaceState()
    }

    func showOpenPanel() {
        guard activeFilePanel == nil else { return }

        let panel = NSOpenPanel()
        panel.title = String(localized: "Open Markdown Files")
        panel.prompt = String(localized: "Open")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [Self.markdownType, .plainText]
        activeFilePanel = panel

        presentAfterCurrentEvent(panel) { [weak self] response in
            guard let self else { return }
            activeFilePanel = nil
            guard response == .OK else { return }
            open(urls: panel.urls)
        }
    }

    @discardableResult
    func open(urls: [URL]) -> Bool {
        let acceptedURLs = urls.filter(Self.isSupportedDocument)
        guard handleUnsupportedOpen(urls: urls, acceptedURLs: acceptedURLs) else { return false }
        let lastOpenedDocument = openAcceptedURLs(acceptedURLs)

        if let lastOpenedDocument {
            selectedDocumentID = lastOpenedDocument.id
            persistWorkspaceState()
            return true
        }
        return false
    }

    private func openAcceptedURLs(_ urls: [URL]) -> DocumentItem? {
        var lastOpenedDocument: DocumentItem?
        for url in urls {
            if let document = open(url) { lastOpenedDocument = document }
        }
        return lastOpenedDocument
    }

    private func handleUnsupportedOpen(urls: [URL], acceptedURLs: [URL]) -> Bool {
        guard !acceptedURLs.isEmpty else {
            if !urls.isEmpty {
                presentedError = AppError(
                    title: "Unsupported File",
                    message: String(localized: "Choose a Markdown or plain-text file.")
                )
            }
            return false
        }
        return true
    }

    private func open(_ url: URL) -> DocumentItem? {
        let standardizedURL = url.standardizedFileURL
        if let existing = openDocuments.first(where: { $0.fileURL?.standardizedFileURL == standardizedURL }) {
            addRecentFile(standardizedURL)
            return existing
        }
        do {
            let text = try withSecurityScope(standardizedURL) {
                try String(contentsOf: standardizedURL, encoding: .utf8)
            }
            let document = DocumentItem(fileURL: standardizedURL, text: text)
            openDocuments.append(document)
            addRecentFile(standardizedURL)
            return document
        } catch {
            presentedError = AppError(
                title: "Couldn't Open \(standardizedURL.lastPathComponent)",
                message: error.localizedDescription
            )
            return nil
        }
    }

    func saveSelected() {
        guard let selectedDocument else { return }
        save(selectedDocument)
    }

    @discardableResult
    func save(_ document: DocumentItem) -> Bool {
        guard let fileURL = document.fileURL else {
            presentSavePanel(for: document)
            return false
        }

        do {
            let didAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            try document.text.write(
                to: fileURL,
                atomically: true,
                encoding: .utf8
            )
            document.markSaved()
            addRecentFile(fileURL)
            return true
        } catch {
            presentedError = AppError(
                title: "Couldn't Save \(document.filename)",
                message: error.localizedDescription
            )
            return false
        }
    }

    func saveSelectedAs() {
        guard let selectedDocument else { return }
        presentSavePanel(for: selectedDocument)
    }

    func scheduleAutosave(for document: DocumentItem) {
        autosaveTasks[document.id]?.cancel()
        guard preferences.autosave, document.fileURL != nil else {
            autosaveTasks[document.id] = nil
            return
        }

        autosaveTasks[document.id] = Task { [weak self, weak document] in
            try? await Task.sleep(for: AppPreferences.autosaveDelay)
            guard !Task.isCancelled,
                  let self,
                  let document,
                  preferences.autosave,
                  document.isDirty else {
                return
            }
            _ = save(document)
            autosaveTasks[document.id] = nil
        }
    }

    func saveAndClose(_ document: DocumentItem) {
        if document.fileURL == nil {
            presentSavePanel(for: document, closeAfterSaving: true)
        } else if save(document) {
            close(document)
        }
    }

    func closeSelectedPromptingIfNeeded() {
        guard let selectedDocument else { return }
        guard selectedDocument.isDirty else {
            close(selectedDocument)
            return
        }

        presentCloseAlert(for: selectedDocument)
    }

    private func presentCloseAlert(for document: DocumentItem) {

        let alert = NSAlert()
        alert.messageText = String(localized: "Save changes to \(document.filename)?")
        alert.informativeText = String(localized: "Your changes will be lost if you close this document without saving.")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "Save"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: String(localized: "Don't Save"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveAndClose(document)
        case .alertThirdButtonReturn:
            close(document)
        default:
            break
        }
    }

    /// Prevents the standard window-close-to-quit behavior from silently
    /// discarding edits. The caller terminates only after the person chooses
    /// the explicit "Quit Without Saving" action.
    func confirmTermination() -> Bool {
        let dirtyDocuments = openDocuments.filter(\.isDirty)
        guard !dirtyDocuments.isEmpty else { return true }

        return terminationChoice(for: dirtyDocuments)
    }

    private func terminationChoice(for dirtyDocuments: [DocumentItem]) -> Bool {

        let alert = NSAlert()
        alert.messageText = terminationMessage(for: dirtyDocuments.count)
        alert.informativeText = String(localized: "Save your changes before quitting, or choose Quit Without Saving to discard them.")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: String(localized: "Quit Without Saving"))
        alert.addButton(withTitle: String(localized: "Review Documents"))

        switch alert.runModal() {
        case .alertSecondButtonReturn:
            return true
        case .alertThirdButtonReturn:
            selectedDocumentID = dirtyDocuments.first?.id
            return false
        default:
            return false
        }
    }

    private func terminationMessage(for count: Int) -> String {
        count == 1
            ? String(localized: "This document has unsaved changes.")
            : String(localized: "Some documents have unsaved changes.")
    }

    func withSecurityScope<T>(_ url: URL, operation: () throws -> T) rethrows -> T {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        return try operation()
    }
}
