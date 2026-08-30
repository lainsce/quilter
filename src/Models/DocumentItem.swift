import Foundation
import Observation

@MainActor
@Observable
final class DocumentItem: Identifiable {
    private static let derivedStateDelay = Duration.milliseconds(180)

    let id: UUID
    var fileURL: URL?
    private var untitledName: String
    var text: String {
        didSet {
            guard text != oldValue else { return }
            isDirty = fileURL == nil || text != lastSavedText
            scheduleDerivedStateRefresh()
        }
    }
    private(set) var headings: [HeadingItem]
    private(set) var tags: [String]
    private(set) var sentenceCount: Int
    private(set) var wordCount: Int
    private(set) var isDirty: Bool
    private(set) var lastSavedText: String
    var scrollTarget: EditorScrollTarget?
    @ObservationIgnored private var derivedStateTask: Task<Void, Never>?

    var filename: String {
        fileURL?.lastPathComponent ?? untitledName
    }

    var directoryDisplayName: String {
        guard let fileURL else { return String(localized: "Not Saved") }
        // Directory URLs report a trailing slash, so strip it before appending
        // our own to avoid a doubled "//".
        var path = fileURL.deletingLastPathComponent().path(percentEncoded: false)
        while path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        let home = Self.realHomeDirectory

        if path == home {
            return "~/"
        }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count) + "/"
        }
        return path + "/"
    }

    /// The user's real home directory. `URL.homeDirectory` returns the sandbox
    /// container under App Sandbox, so we read the account's home from the
    /// password database, which the sandbox does not remap.
    private static let realHomeDirectory: String = {
        if let dir = getpwuid(getuid())?.pointee.pw_dir {
            return String(cString: dir)
        }
        return URL.homeDirectory.path(percentEncoded: false)
    }()

    var summary: String? {
        headings.first?.title
    }

    var readingTimeMinutes: Int {
        wordCount == 0 ? 0 : (wordCount + 199) / 200
    }

    init(
        id: UUID = UUID(),
        fileURL: URL,
        text: String
    ) {
        self.id = id
        self.fileURL = fileURL
        self.untitledName = fileURL.lastPathComponent
        self.text = text
        let derivedState = MarkdownParser.derivedState(in: text)
        self.headings = derivedState.headings
        self.tags = derivedState.tags
        self.sentenceCount = derivedState.sentenceCount
        self.wordCount = derivedState.wordCount
        self.isDirty = false
        self.lastSavedText = text
    }

    init(
        id: UUID = UUID(),
        untitledName: String,
        text: String = ""
    ) {
        self.id = id
        self.fileURL = nil
        self.untitledName = untitledName
        self.text = text
        let derivedState = MarkdownParser.derivedState(in: text)
        self.headings = derivedState.headings
        self.tags = derivedState.tags
        self.sentenceCount = derivedState.sentenceCount
        self.wordCount = derivedState.wordCount
        self.isDirty = true
        self.lastSavedText = ""
    }

    func markSaved(at url: URL? = nil) {
        fileURL = url ?? fileURL
        lastSavedText = text
        isDirty = false
    }

    func renameUntitledDocument(to filename: String) {
        guard fileURL == nil else { return }
        untitledName = filename
    }

    func updateFileURL(_ url: URL) {
        fileURL = url
    }

    func requestScroll(to heading: HeadingItem) {
        scrollTarget = EditorScrollTarget(range: heading.textRange)
    }

    private func scheduleDerivedStateRefresh() {
        let textSnapshot = text
        derivedStateTask?.cancel()
        derivedStateTask = Task { [weak self] in
            try? await Task.sleep(for: Self.derivedStateDelay)
            guard !Task.isCancelled else { return }

            let analysisTask = Task.detached(priority: .userInitiated) {
                MarkdownParser.derivedState(in: textSnapshot)
            }
            let derivedState = await withTaskCancellationHandler {
                await analysisTask.value
            } onCancel: {
                analysisTask.cancel()
            }

            guard !Task.isCancelled,
                  let self,
                  self.text == textSnapshot else {
                return
            }
            apply(derivedState)
            derivedStateTask = nil
        }
    }

    private func apply(_ derivedState: MarkdownDerivedState) {
        headings = Self.preservingHeadingIdentity(
            in: derivedState.headings,
            previousHeadings: headings
        )
        tags = derivedState.tags
        sentenceCount = derivedState.sentenceCount
        wordCount = derivedState.wordCount
    }

    private static func preservingHeadingIdentity(
        in newHeadings: [HeadingItem],
        previousHeadings: [HeadingItem]
    ) -> [HeadingItem] {
        var unmatchedPreviousHeadings = previousHeadings

        return newHeadings.map { heading in
            guard let matchingIndex = unmatchedPreviousHeadings.indices
                .filter({ index in
                    let previous = unmatchedPreviousHeadings[index]
                    return previous.level == heading.level && previous.title == heading.title
                })
                .min(by: { first, second in
                    let firstDistance = abs(
                        unmatchedPreviousHeadings[first].textRange.location - heading.textRange.location
                    )
                    let secondDistance = abs(
                        unmatchedPreviousHeadings[second].textRange.location - heading.textRange.location
                    )
                    return firstDistance < secondDistance
                }) else {
                return heading
            }

            let previousHeading = unmatchedPreviousHeadings.remove(at: matchingIndex)
            return HeadingItem(
                id: previousHeading.id,
                title: heading.title,
                level: heading.level,
                textRange: heading.textRange
            )
        }
    }
}
