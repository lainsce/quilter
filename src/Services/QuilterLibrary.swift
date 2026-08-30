import AppKit
import Foundation
import UniformTypeIdentifiers

/// Resolves the files referenced by `:image` and `:file` directives.
///
/// The default library lives inside the app's sandbox container. A person can
/// choose another folder from Settings; that folder is retained with a
/// security-scoped bookmark rather than through a temporary sandbox exception.
enum QuilterLibrary {
    static let folderName = "Quilter"

    private static let bookmarkKey = "Quilter.LibraryFolderBookmark"
    private static let iconSetKey = "Quilter.LibraryIconSet.v3"

    private static var defaultRootURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL.applicationSupportDirectory
        return applicationSupport
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
    }

    static var rootURL: URL {
        selectedFolderURL() ?? defaultRootURL
    }

    static var isUsingSelectedFolder: Bool {
        selectedFolderURL() != nil
    }

    static var locationDescription: String {
        let path = rootURL.path(percentEncoded: false)
        let home = URL.homeDirectory.path(percentEncoded: false)
        guard path.hasPrefix(home + "/") else { return path }
        return "~" + path.dropFirst(home.count)
    }

    @MainActor
    static func prepare() {
        let root = rootURL
        try? FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: iconSetKey), isUsingSelectedFolder else {
            return
        }
        let didAccess = root.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                root.stopAccessingSecurityScopedResource()
            }
        }
        if applyFolderIcon(at: root) {
            defaults.set(true, forKey: iconSetKey)
        }
    }

    /// Presents a standard folder chooser and persists the selected folder's
    /// security scope for the next launch.
    @MainActor
    @discardableResult
    static func chooseFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.title = String(localized: "Choose Library Folder")
        panel.prompt = String(localized: "Use This Folder")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            UserDefaults.standard.removeObject(forKey: iconSetKey)
            prepare()
            return true
        } catch {
            return false
        }
    }

    @MainActor
    static func useDefaultFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: iconSetKey)
        prepare()
    }

    @MainActor
    static func revealInFinder() {
        let root = rootURL
        try? FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        let didAccess = root.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                root.stopAccessingSecurityScopedResource()
            }
        }
        NSWorkspace.shared.activateFileViewerSelecting([root])
    }

    /// Reads a library file while its security scope is active.
    static func readData(at relativePath: String) -> (url: URL, data: Data)? {
        withRootAccess { root in
            guard let url = resolvedURL(for: relativePath, in: root),
                  let data = try? Data(contentsOf: url) else {
                return nil
            }
            return (url, data)
        }
    }

    /// Reads a UTF-8 library file while its security scope is active.
    static func readText(at relativePath: String) -> (url: URL, text: String)? {
        withRootAccess { root in
            guard let url = resolvedURL(for: relativePath, in: root),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            return (url, text)
        }
    }

    private static func withRootAccess<T>(_ body: (URL) -> T) -> T {
        let root = rootURL
        try? FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        let didAccess = root.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                root.stopAccessingSecurityScopedResource()
            }
        }
        return body(root)
    }

    private static func selectedFolderURL() -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            if let refreshed = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
            }
        }
        return url
    }

    private static func resolvedURL(for path: String, in root: URL) -> URL? {
        var relative = path.trimmingCharacters(in: .whitespacesAndNewlines)
        while relative.hasPrefix("/") {
            relative.removeFirst()
        }
        guard !relative.isEmpty else { return nil }

        let rootPath = root.standardizedFileURL.path
        let candidate = root
            .appendingPathComponent(relative)
            .standardizedFileURL
        guard candidate.path == rootPath || candidate.path.hasPrefix(rootPath + "/") else {
            return nil
        }
        return candidate
    }

    @MainActor
    private static func applyFolderIcon(at url: URL) -> Bool {
        let side: CGFloat = 512
        let canvas = NSSize(width: side, height: side)

        let folderIcon = NSWorkspace.shared.icon(for: .folder)
        folderIcon.size = canvas

        let appIcon = NSApp.applicationIconImage
            ?? NSImage(named: NSImage.applicationIconName)

        let composed = NSImage(size: canvas)
        composed.lockFocus()
        folderIcon.draw(in: NSRect(origin: .zero, size: canvas))

        let overlaySide = side * 0.58
        let overlayRect = NSRect(
            x: (side - overlaySide) / 2,
            y: (side - overlaySide) / 2 - side * 0.05,
            width: overlaySide,
            height: overlaySide
        )
        appIcon?.draw(
            in: overlayRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        composed.unlockFocus()

        return NSWorkspace.shared.setIcon(composed, forFile: url.path, options: [])
    }
}
