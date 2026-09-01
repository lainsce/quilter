import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppState {
    static let markdownType = UTType(filenameExtension: "md") ?? .plainText

    enum DefaultsKey {
        static let sidebarVisible = "Quilter.SidebarVisible"
        static let recentFiles = "Quilter.RecentFiles"
        static let recentFileBookmarks = "Quilter.RecentFileBookmarks"
        static let openDocumentBookmarks = "Quilter.OpenDocumentBookmarks"
        static let selectedDocumentPath = "Quilter.SelectedDocumentPath"
        static let editorLayout = "Quilter.EditorLayout"
    }

    let preferences: AppPreferences
    var openDocuments: [DocumentItem] = []
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

    var recentFileURLs: [URL] = []
    @ObservationIgnored var activeFilePanel: NSSavePanel?
    @ObservationIgnored var autosaveTasks: [UUID: Task<Void, Never>] = [:]

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


}
