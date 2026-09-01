import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
extension AppState {
    func presentSavePanel(
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

    func presentAfterCurrentEvent(
        _ panel: NSSavePanel,
        completion: @escaping @MainActor (NSApplication.ModalResponse) -> Void
    ) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard let self, activeFilePanel === panel else { return }
            panel.begin(completionHandler: completion)
        }
    }

    func save(
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

    func selectDocument(offset: Int) {
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

    func addRecentFile(_ url: URL) {
        let standardizedURL = url.standardizedFileURL
        recentFileURLs.removeAll { $0.standardizedFileURL == standardizedURL }
        recentFileURLs.insert(standardizedURL, at: 0)
        recentFileURLs = Array(recentFileURLs.prefix(8))

        persistRecentFiles()
        NSDocumentController.shared.noteNewRecentDocumentURL(standardizedURL)
    }

    func persistRecentFiles() {
        let defaults = UserDefaults.standard
        let bookmarks = recentFileURLs.compactMap { securityScopedBookmark(for: $0) }
        defaults.set(bookmarks, forKey: DefaultsKey.recentFileBookmarks)
        defaults.set(
            recentFileURLs.map { $0.path(percentEncoded: false) },
            forKey: DefaultsKey.recentFiles
        )
    }

    func restoreRecentFiles(from defaults: UserDefaults) -> [URL] {
        let bookmarks = defaults.array(forKey: DefaultsKey.recentFileBookmarks) as? [Data] ?? []
        var refreshedBookmarks: [Data] = []
        var restoredURLs = restoreBookmarkFiles(bookmarks, refreshedBookmarks: &refreshedBookmarks)

        if !refreshedBookmarks.isEmpty {
            defaults.set(refreshedBookmarks, forKey: DefaultsKey.recentFileBookmarks)
        }

        // Keep legacy paths only for files inside the app container. External
        // paths must be selected again so the user can grant a new scope.
        if restoredURLs.isEmpty {
            restoredURLs = restoreLegacyFiles(from: defaults)
        }

        return Array(restoredURLs.prefix(8))
    }

    private func restoreBookmarkFiles(
        _ bookmarks: [Data],
        refreshedBookmarks: inout [Data]
    ) -> [URL] {
        var restoredURLs: [URL] = []
        for bookmark in bookmarks {
            var refreshedBookmark: Data?
            guard let url = resolveSecurityScopedBookmark(bookmark, refreshedBookmark: &refreshedBookmark),
                  FileManager.default.fileExists(atPath: url.path) else { continue }
            restoredURLs.append(url.standardizedFileURL)
            refreshedBookmarks.append(refreshedBookmark ?? bookmark)
        }
        return restoredURLs
    }

    private func restoreLegacyFiles(from defaults: UserDefaults) -> [URL] {
        let containerRoot = URL.homeDirectory.standardizedFileURL.path
        let legacyPaths = defaults.stringArray(forKey: DefaultsKey.recentFiles) ?? []
        return legacyPaths.compactMap { legacyURL(for: $0, rootPath: containerRoot) }
    }

    private func legacyURL(for path: String, rootPath: String) -> URL? {
        let url = URL(filePath: path).standardizedFileURL
        guard url.path == rootPath || url.path.hasPrefix(rootPath + "/") else { return nil }
        if FileManager.default.fileExists(atPath: url.path) { return url }
        return nil
    }
}
