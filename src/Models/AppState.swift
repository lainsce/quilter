import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppState {
    private static let markdownType = UTType(filenameExtension: "md") ?? .plainText

    private enum DefaultsKey {
        static let sidebarVisible = "Quilter.SidebarVisible"
        static let recentFiles = "Quilter.RecentFiles"
        static let recentFileBookmarks = "Quilter.RecentFileBookmarks"
        static let openDocumentBookmarks = "Quilter.OpenDocumentBookmarks"
        static let selectedDocumentPath = "Quilter.SelectedDocumentPath"
        static let editorLayout = "Quilter.EditorLayout"
    }

    let preferences: AppPreferences
    private(set) var openDocuments: [DocumentItem] = []
    var selectedDocumentID: UUID?
    var isFocusMode = false {
        didSet {
            if isFocusMode {
                editorLayout = .editorOnly
            }
        }
    }
    /// Keeps the toolbar chrome visible while a toolbar-anchored popover is
    /// being used. Without this, hover mode can fade the anchor out as the
    /// pointer travels from the ellipsis button into its popover.
    var isToolbarPopoverPresented = false
    var editorLayout: EditorLayout {
        didSet {
            UserDefaults.standard.set(editorLayout.rawValue, forKey: DefaultsKey.editorLayout)
        }
    }
    var isSidebarVisible: Bool {
        didSet {
            UserDefaults.standard.set(isSidebarVisible, forKey: DefaultsKey.sidebarVisible)
        }
    }
    var presentedError: AppError?

    /// When set, the sidebar file list is filtered to documents carrying this tag.
    var selectedTag: String?

    private(set) var recentFileURLs: [URL] = []
    @ObservationIgnored private var activeFilePanel: NSSavePanel?
    @ObservationIgnored private var autosaveTasks: [UUID: Task<Void, Never>] = [:]

    var selectedDocument: DocumentItem? {
        guard let selectedDocumentID else { return nil }
        return openDocuments.first { $0.id == selectedDocumentID }
    }

    var canCycleDocuments: Bool {
        openDocuments.count > 1
    }

    /// Unique tags across all open documents, sorted case-insensitively.
    var allTags: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for document in openDocuments {
            for tag in document.tags where seen.insert(tag.lowercased()).inserted {
                result.append(tag)
            }
        }
        return result.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Open documents filtered by `selectedTag`, or all of them when no tag is
    /// selected.
    var filteredDocuments: [DocumentItem] {
        guard let selectedTag else { return openDocuments }
        let key = selectedTag.lowercased()
        return openDocuments.filter { document in
            document.tags.contains { $0.lowercased() == key }
        }
    }

    func toggleTagFilter(_ tag: String) {
        if selectedTag?.lowercased() == tag.lowercased() {
            selectedTag = nil
        } else {
            selectedTag = tag
        }
    }

    init(preferences: AppPreferences) {
        self.preferences = preferences
        let defaults = UserDefaults.standard
        editorLayout = EditorLayout(
            rawValue: defaults.string(forKey: DefaultsKey.editorLayout) ?? ""
        ) ?? .editorOnly
        if defaults.object(forKey: DefaultsKey.sidebarVisible) == nil {
            isSidebarVisible = true
        } else {
            isSidebarVisible = defaults.bool(forKey: DefaultsKey.sidebarVisible)
        }

        recentFileURLs = restoreRecentFiles(from: defaults)
        restoreWorkspaceState()
    }

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
        switch editorLayout {
        case .editorOnly: editorLayout = .split
        case .split: editorLayout = .previewOnly
        case .previewOnly: editorLayout = .editorOnly
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

        guard filename != selectedDocument.filename else { return true }

        guard let oldURL = selectedDocument.fileURL else {
            selectedDocument.renameUntitledDocument(to: filename)
            return true
        }

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
            let didAccess = oldURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    oldURL.stopAccessingSecurityScopedResource()
                }
            }

            try FileManager.default.moveItem(at: oldURL, to: newURL)
            selectedDocument.updateFileURL(newURL)
            recentFileURLs.removeAll { $0.standardizedFileURL == oldURL.standardizedFileURL }
            addRecentFile(newURL)
            persistWorkspaceState()
            return true
        } catch {
            presentedError = AppError(
                title: "Couldn't Rename \(selectedDocument.filename)",
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
        guard !acceptedURLs.isEmpty else {
            if !urls.isEmpty {
                presentedError = AppError(
                    title: "Unsupported File",
                    message: String(localized: "Choose a Markdown or plain-text file.")
                )
            }
            return false
        }

        var lastOpenedDocument: DocumentItem?

        for url in acceptedURLs {
            let standardizedURL = url.standardizedFileURL
            if let existing = openDocuments.first(where: {
                $0.fileURL?.standardizedFileURL == standardizedURL
            }) {
                lastOpenedDocument = existing
                addRecentFile(standardizedURL)
                continue
            }

            do {
                let didAccess = standardizedURL.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        standardizedURL.stopAccessingSecurityScopedResource()
                    }
                }

                let text = try String(contentsOf: standardizedURL, encoding: .utf8)
                let document = DocumentItem(fileURL: standardizedURL, text: text)
                openDocuments.append(document)
                lastOpenedDocument = document
                addRecentFile(standardizedURL)
            } catch {
                presentedError = AppError(
                    title: "Couldn't Open \(standardizedURL.lastPathComponent)",
                    message: error.localizedDescription
                )
            }
        }

        if let lastOpenedDocument {
            selectedDocumentID = lastOpenedDocument.id
            persistWorkspaceState()
            return true
        }
        return false
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

        let alert = NSAlert()
        alert.messageText = String(localized: "Save changes to \(selectedDocument.filename)?")
        alert.informativeText = String(localized: "Your changes will be lost if you close this document without saving.")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "Save"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: String(localized: "Don't Save"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveAndClose(selectedDocument)
        case .alertThirdButtonReturn:
            close(selectedDocument)
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

        let alert = NSAlert()
        alert.messageText = dirtyDocuments.count == 1
            ? String(localized: "This document has unsaved changes.")
            : String(localized: "Some documents have unsaved changes.")
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

    private func presentSavePanel(
        for document: DocumentItem,
        closeAfterSaving: Bool = false
    ) {
        guard activeFilePanel == nil else { return }

        let panel = NSSavePanel()
        panel.title = String(localized: "Save Markdown File")
        panel.prompt = String(localized: "Save")
        panel.allowedContentTypes = [Self.markdownType, .plainText]
        panel.nameFieldStringValue = document.filename
        panel.directoryURL = document.fileURL?.deletingLastPathComponent()
        activeFilePanel = panel

        presentAfterCurrentEvent(panel) { [weak self] response in
            guard let self else { return }
            activeFilePanel = nil
            guard response == .OK, let url = panel.url else { return }
            save(document, to: url, closeAfterSaving: closeAfterSaving)
        }
    }

    private func presentAfterCurrentEvent(
        _ panel: NSSavePanel,
        completion: @escaping @MainActor (NSApplication.ModalResponse) -> Void
    ) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard let self, activeFilePanel === panel else { return }
            panel.begin(completionHandler: completion)
        }
    }

    private func save(
        _ document: DocumentItem,
        to url: URL,
        closeAfterSaving: Bool
    ) {
        do {
            try document.text.write(to: url, atomically: true, encoding: .utf8)
            document.markSaved(at: url)
            addRecentFile(url)
            persistWorkspaceState()
            if closeAfterSaving {
                close(document)
            }
        } catch {
            presentedError = AppError(
                title: "Couldn't Save \(url.lastPathComponent)",
                message: error.localizedDescription
            )
        }
    }

    func close(_ document: DocumentItem) {
        guard let index = openDocuments.firstIndex(where: { $0.id == document.id }) else {
            return
        }

        autosaveTasks[document.id]?.cancel()
        autosaveTasks[document.id] = nil
        let wasSelected = selectedDocumentID == document.id
        openDocuments.remove(at: index)

        if wasSelected {
            if openDocuments.indices.contains(index) {
                selectedDocumentID = openDocuments[index].id
            } else {
                selectedDocumentID = openDocuments.last?.id
            }
        }

        persistWorkspaceState()
    }

    func closeSelectedIfClean() {
        guard let selectedDocument, !selectedDocument.isDirty else { return }
        close(selectedDocument)
    }

    func clearRecentFiles() {
        recentFileURLs.removeAll()
        UserDefaults.standard.removeObject(forKey: DefaultsKey.recentFiles)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.recentFileBookmarks)
        NSDocumentController.shared.clearRecentDocuments(nil)
    }

    private func selectDocument(offset: Int) {
        guard !openDocuments.isEmpty else { return }

        guard let selectedDocumentID,
              let currentIndex = openDocuments.firstIndex(where: { $0.id == selectedDocumentID }) else {
            self.selectedDocumentID = openDocuments.first?.id
            persistWorkspaceState()
            return
        }

        let nextIndex = (currentIndex + offset + openDocuments.count) % openDocuments.count
        self.selectedDocumentID = openDocuments[nextIndex].id
        persistWorkspaceState()
    }

    private func addRecentFile(_ url: URL) {
        let standardizedURL = url.standardizedFileURL
        recentFileURLs.removeAll { $0.standardizedFileURL == standardizedURL }
        recentFileURLs.insert(standardizedURL, at: 0)
        recentFileURLs = Array(recentFileURLs.prefix(8))

        persistRecentFiles()
        NSDocumentController.shared.noteNewRecentDocumentURL(standardizedURL)
    }

    private func persistRecentFiles() {
        let defaults = UserDefaults.standard
        let bookmarks = recentFileURLs.compactMap { securityScopedBookmark(for: $0) }
        defaults.set(bookmarks, forKey: DefaultsKey.recentFileBookmarks)
        defaults.set(
            recentFileURLs.map { $0.path(percentEncoded: false) },
            forKey: DefaultsKey.recentFiles
        )
    }

    private func restoreRecentFiles(from defaults: UserDefaults) -> [URL] {
        let bookmarks = defaults.array(forKey: DefaultsKey.recentFileBookmarks) as? [Data] ?? []
        var restoredURLs: [URL] = []
        var refreshedBookmarks: [Data] = []

        for bookmark in bookmarks {
            var refreshedBookmark: Data?
            guard let url = resolveSecurityScopedBookmark(
                bookmark,
                refreshedBookmark: &refreshedBookmark
            ),
                  FileManager.default.fileExists(atPath: url.path) else {
                continue
            }
            restoredURLs.append(url.standardizedFileURL)
            refreshedBookmarks.append(refreshedBookmark ?? bookmark)
        }

        if !refreshedBookmarks.isEmpty {
            defaults.set(refreshedBookmarks, forKey: DefaultsKey.recentFileBookmarks)
        }

        // Keep legacy paths only for files inside the app container. External
        // paths must be selected again so the user can grant a new scope.
        if restoredURLs.isEmpty {
            let containerRoot = URL.homeDirectory.standardizedFileURL.path
            let legacyPaths = defaults.stringArray(forKey: DefaultsKey.recentFiles) ?? []
            restoredURLs = legacyPaths.compactMap { path in
                let url = URL(filePath: path).standardizedFileURL
                guard url.path == containerRoot || url.path.hasPrefix(containerRoot + "/") else {
                    return nil
                }
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
        }

        return Array(restoredURLs.prefix(8))
    }

    private func restoreWorkspaceState() {
        let defaults = UserDefaults.standard
        let bookmarks = defaults.array(forKey: DefaultsKey.openDocumentBookmarks) as? [Data] ?? []
        let selectedPath = defaults.string(forKey: DefaultsKey.selectedDocumentPath)

        var restoredDocuments: [DocumentItem] = []

        for bookmark in bookmarks {
            var refreshedBookmark: Data?
            guard let url = resolveSecurityScopedBookmark(
                bookmark,
                refreshedBookmark: &refreshedBookmark
            ) else {
                continue
            }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }

            restoredDocuments.append(DocumentItem(fileURL: url, text: text))
        }

        openDocuments = restoredDocuments
        selectedDocumentID = restoredDocuments.first {
            $0.fileURL?.path(percentEncoded: false) == selectedPath
        }?.id ?? restoredDocuments.first?.id

        persistWorkspaceState()
    }

    private func persistWorkspaceState() {
        let defaults = UserDefaults.standard
        let bookmarks: [Data] = openDocuments.compactMap { document -> Data? in
            guard let url = document.fileURL else { return nil }
            return securityScopedBookmark(for: url)
        }

        defaults.set(bookmarks, forKey: DefaultsKey.openDocumentBookmarks)

        if let selectedPath = selectedDocument?.fileURL?.path(percentEncoded: false) {
            defaults.set(selectedPath, forKey: DefaultsKey.selectedDocumentPath)
        } else {
            defaults.removeObject(forKey: DefaultsKey.selectedDocumentPath)
        }
    }

    private func resolveSecurityScopedBookmark(
        _ bookmark: Data,
        refreshedBookmark: inout Data?
    ) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        guard isStale else { return url }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        refreshedBookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return url
    }

    private func securityScopedBookmark(for url: URL) -> Data? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    private static func isSupportedDocument(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
        return contentType?.conforms(to: .plainText) == true
            || contentType?.conforms(to: Self.markdownType) == true
            || ["md", "markdown", "mdown", "txt", "text"].contains(url.pathExtension.lowercased())
    }

    private static func isValidFilename(_ filename: String) -> Bool {
        !filename.isEmpty
            && filename != "."
            && filename != ".."
            && !filename.contains("/")
            && !filename.contains(":")
    }
}
