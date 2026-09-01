import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
extension AppState {
    func restoreWorkspaceState() {
        let defaults = UserDefaults.standard
        let bookmarks = defaults.array(forKey: DefaultsKey.openDocumentBookmarks) as? [Data] ?? []
        let selectedPath = defaults.string(forKey: DefaultsKey.selectedDocumentPath)
        let restoredDocuments = restoreDocuments(from: bookmarks)

        openDocuments = restoredDocuments
        selectedDocumentID = restoredDocuments.first {
            $0.fileURL?.path(percentEncoded: false) == selectedPath
        }?.id ?? restoredDocuments.first?.id

        persistWorkspaceState()
    }

    private func restoreDocuments(from bookmarks: [Data]) -> [DocumentItem] {
        var documents: [DocumentItem] = []
        for bookmark in bookmarks {
            var refreshedBookmark: Data?
            guard let url = resolveSecurityScopedBookmark(bookmark, refreshedBookmark: &refreshedBookmark) else {
                continue
            }
            guard let text = try? withSecurityScope(url, operation: {
                try String(contentsOf: url, encoding: .utf8)
            }) else { continue }
            documents.append(DocumentItem(fileURL: url, text: text))
        }
        return documents
    }

    func persistWorkspaceState() {
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

    func resolveSecurityScopedBookmark(
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

    func securityScopedBookmark(for url: URL) -> Data? {
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

    static func isSupportedDocument(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
        return contentType?.conforms(to: .plainText) == true
            || contentType?.conforms(to: Self.markdownType) == true
            || ["md", "markdown", "mdown", "txt", "text"].contains(url.pathExtension.lowercased())
    }

    static func isValidFilename(_ filename: String) -> Bool {
        [
            !filename.isEmpty,
            filename != ".",
            filename != "..",
            !filename.contains("/"),
            !filename.contains(":"),
        ].allSatisfy { $0 }
    }
}
