import AppKit
import SwiftUI

private final class ColumnTextView: NSTextView {
    private let verticalInset: CGFloat = MarkdownColumnLayout.verticalInset

    /// Left gutter (in points) reserved by the paragraph head indent for hanging
    /// heading markers. The container inset is reduced by this amount so the body
    /// text stays centered while the markers hang into the reclaimed space.
    var markerGutter: CGFloat = 0 {
        didSet {
            guard markerGutter != oldValue else { return }
            updateColumnInsets()
        }
    }

    private var targetTextWidth: CGFloat = 0

    func configureColumn(
        font: NSFont,
        characterCount: Int = 64
    ) {
        // Exact for monospaced fonts. An approximation for proportional fonts.
        targetTextWidth = MarkdownColumnLayout.textWidth(
            font: font,
            characterCount: characterCount
        )

        updateColumnInsets()
    }

    override func layout() {
        super.layout()
        updateColumnInsets()
    }

    private func updateColumnInsets() {
        guard bounds.width > 0, targetTextWidth > 0 else {
            return
        }

        // The character-count preference is the body's maximum width. When the
        // pane is wide enough, center a column of exactly targetTextWidth (the
        // block also reserves the marker gutter so the wrapped text stays that
        // wide while "#" markers hang into the left margin). When the pane is
        // narrower — e.g. the split-view editor — the body simply fills the
        // available width down to a modest minimum margin.
        let layout = MarkdownColumnLayout(
            availableWidth: bounds.width,
            targetTextWidth: targetTextWidth,
            markerGutter: markerGutter
        )
        let horizontalInset = layout.horizontalInset

        let newInset = NSSize(
            width: horizontalInset,
            height: verticalInset
        )

        guard textContainerInset != newInset else {
            return
        }

        textContainerInset = newInset

        // Changing the inset invalidates glyph layout. Force it to complete
        // now so the text is laid out before the next draw pass — otherwise
        // the view draws with no glyphs (text vanishes, only caret remains).
        if let container = textContainer {
            layoutManager?.ensureLayout(for: container)
        }
    }

}

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let scrollTarget: EditorScrollTarget?
    let isFocusMode: Bool
    @Bindable var preferences: AppPreferences
    var syncScrollRatio: Binding<CGFloat>? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    static func editorBackground() -> NSColor {
        AppTheme.configuredEditorSurfaceColor()
    }

    static func editorTextColor() -> NSColor {
        return .labelColor
    }

    static func editorAccentColor() -> NSColor {
        NSColor(AppTheme.accentColor)
    }

    /// Selection highlight tinted with the themed accent, replacing the system
    /// selection color so highlighted text matches the rest of the app's accent.
    static func editorSelectionColor() -> NSColor {
        editorAccentColor()
            .withAlphaComponent(0.3)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView(frame: .zero)
        let textView = ColumnTextView(frame: .zero)

        scrollView.documentView = textView

        let font = preferences.editorFont.font(ofSize: AppTheme.editorFontPointSize)
        let bg = Self.editorBackground()
        let textColor = Self.editorTextColor()

        let paragraphStyle = NSMutableParagraphStyle()
        // Use an explicit typographic line height. Markdown blank lines then
        // contribute one additional 28-point row instead of an arbitrary
        // amount of extra spacing.
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = AppTheme.editorLineHeight
        paragraphStyle.maximumLineHeight = AppTheme.editorLineHeight
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0
        // Reserve a left gutter matching the deepest heading present so ordinary
        // text aligns with heading bodies while "#" markers hang into the gutter.
        let headingGutter = MarkdownSyntaxHighlighter.headingIndent(
            for: preferences.editorFont,
            maxLevel: MarkdownSyntaxHighlighter.maxHeadingLevel(in: text)
        )
        paragraphStyle.firstLineHeadIndent = headingGutter
        paragraphStyle.headIndent = headingGutter

        textView.delegate = context.coordinator
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false

        textView.font = font
        textView.textColor = textColor
        textView.insertionPointColor = Self.editorAccentColor()
        textView.selectedTextAttributes = [
            .backgroundColor: Self.editorSelectionColor()
        ]
        textView.backgroundColor = bg
        textView.drawsBackground = true
        textView.defaultParagraphStyle = paragraphStyle

        textView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Avoid an additional five-point padding inside the column.
        textView.textContainer?.lineFragmentPadding = 0

        textView.markerGutter = headingGutter
        textView.configureColumn(
            font: font,
            characterCount: preferences.columnCharacterCount
        )

        textView.setAccessibilityLabel(String(localized: "Markdown Editor"))

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = bg
        scrollView.scrollerStyle = .overlay

        _ = context.coordinator.configure(
            editorFont: preferences.editorFont,
            highlightColor: preferences.highlightColor,
            highlightsNouns: preferences.highlightsNouns,
            highlightsVerbs: preferences.highlightsVerbs,
            highlightsAdjectives: preferences.highlightsAdjectives,
            highlightsAdverbs: preferences.highlightsAdverbs,
            highlightsConjunctions: preferences.highlightsConjunctions,
            checksCliches: preferences.checksCliches,
            checksRedundancies: preferences.checksRedundancies,
            checksFillers: preferences.checksFillers,
            focusScope: preferences.focusScope,
            isFocusMode: isFocusMode,
            usesTypewriterScrolling: preferences.typewriterScrolling
        )

        context.coordinator.applySyntaxHighlighting(to: textView)

        scrollView.contentView.postsBoundsChangedNotifications = true

        context.coordinator.scrollObserver = installScrollObserver(
            on: scrollView,
            coordinator: context.coordinator
        )

        return scrollView
    }

    private func installScrollObserver(
        on scrollView: NSScrollView,
        coordinator: Coordinator
    ) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator] _ in
            MainActor.assumeIsolated {
                guard let coordinator else { return }
                coordinator.syncScrollRatioIfNeeded(on: scrollView)
            }
        }
    }

    func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        guard let textView = scrollView.documentView as? ColumnTextView else {
            return
        }

        let font = preferences.editorFont.font(ofSize: AppTheme.editorFontPointSize)
        let bg = Self.editorBackground()
        updateEditorAppearance(textView, scrollView: scrollView, font: font, background: bg)

        let didChangeSyntaxConfiguration = context.coordinator.configure(
            editorFont: preferences.editorFont,
            highlightColor: preferences.highlightColor,
            highlightsNouns: preferences.highlightsNouns,
            highlightsVerbs: preferences.highlightsVerbs,
            highlightsAdjectives: preferences.highlightsAdjectives,
            highlightsAdverbs: preferences.highlightsAdverbs,
            highlightsConjunctions: preferences.highlightsConjunctions,
            checksCliches: preferences.checksCliches,
            checksRedundancies: preferences.checksRedundancies,
            checksFillers: preferences.checksFillers,
            focusScope: preferences.focusScope,
            isFocusMode: isFocusMode,
            usesTypewriterScrolling: preferences.typewriterScrolling
        )

        let didReplaceText = replaceTextIfNeeded(textView, text: text, coordinator: context.coordinator)
        updateHighlighting(
            didChangeSyntaxConfiguration || didReplaceText,
            textView: textView,
            coordinator: context.coordinator
        )
        context.coordinator.syncScrollRatio = syncScrollRatio
        context.coordinator.syncScrollPositionIfNeeded(on: scrollView)
        scrollToTargetIfNeeded(scrollTarget, textView: textView, coordinator: context.coordinator)
    }

    private func updateEditorAppearance(
        _ textView: ColumnTextView,
        scrollView: NSScrollView,
        font: NSFont,
        background: NSColor
    ) {
        if textView.font != font { textView.font = font }
        textView.backgroundColor = background
        textView.insertionPointColor = Self.editorAccentColor()
        textView.selectedTextAttributes = [.backgroundColor: Self.editorSelectionColor()]
        scrollView.backgroundColor = background
        textView.configureColumn(font: font, characterCount: preferences.columnCharacterCount)
    }

    private func replaceTextIfNeeded(
        _ textView: ColumnTextView,
        text: String,
        coordinator: Coordinator
    ) -> Bool {
        guard textView.string != text else { return false }
        let selectedRanges = textView.selectedRanges
        coordinator.isApplyingExternalChange = true
        textView.string = text
        textView.selectedRanges = selectedRanges.filter {
            NSMaxRange($0.rangeValue) <= (text as NSString).length
        }
        coordinator.isApplyingExternalChange = false
        return true
    }

    private func updateHighlighting(
        _ shouldApply: Bool,
        textView: ColumnTextView,
        coordinator: Coordinator
    ) {
        if shouldApply {
            coordinator.applySyntaxHighlighting(to: textView)
        } else {
            coordinator.updateFocusHighlighting(in: textView)
        }
    }

    private func scrollToTargetIfNeeded(
        _ target: EditorScrollTarget?,
        textView: ColumnTextView,
        coordinator: Coordinator
    ) {
        guard let target, coordinator.lastScrollTargetID != target.id else { return }
        coordinator.lastScrollTargetID = target.id
        textView.scrollRangeToVisible(target.range)
        textView.showFindIndicator(for: target.range)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        var isApplyingExternalChange = false
        private var isApplyingSyntaxHighlighting = false
        private var syntaxHighlightTask: Task<Void, Never>?
        var lastScrollTargetID: UUID?
        var syncScrollRatio: Binding<CGFloat>?
        var ownedScrollRatio: CGFloat = -1
        var scrollObserver: NSObjectProtocol?

        isolated deinit {
            syntaxHighlightTask?.cancel()
            if let scrollObserver {
                NotificationCenter.default.removeObserver(scrollObserver)
            }
        }

        private var editorFont = EditorFontType.quiltMono
        private var highlightColor = MarkdownHighlightColor.yellow
        private var highlightsNouns = false
        private var highlightsVerbs = false
        private var highlightsAdjectives = false
        private var highlightsAdverbs = false
        private var highlightsConjunctions = false
        private var checksCliches = false
        private var checksRedundancies = false
        private var checksFillers = false
        private var focusScope = FocusScope.paragraph
        private var isFocusMode = false
        private var usesTypewriterScrolling = false

        init(text: Binding<String>) {
            _text = text
        }

        @discardableResult
        func configure(
            editorFont: EditorFontType,
            highlightColor: MarkdownHighlightColor,
            highlightsNouns: Bool,
            highlightsVerbs: Bool,
            highlightsAdjectives: Bool,
            highlightsAdverbs: Bool,
            highlightsConjunctions: Bool,
            checksCliches: Bool,
            checksRedundancies: Bool,
            checksFillers: Bool,
            focusScope: FocusScope,
            isFocusMode: Bool,
            usesTypewriterScrolling: Bool
        ) -> Bool {
            let didChangeSyntaxConfiguration = [
                self.editorFont != editorFont,
                self.highlightColor != highlightColor,
                self.highlightsNouns != highlightsNouns,
                self.highlightsVerbs != highlightsVerbs,
                self.highlightsAdjectives != highlightsAdjectives,
                self.highlightsAdverbs != highlightsAdverbs,
                self.highlightsConjunctions != highlightsConjunctions,
                self.checksCliches != checksCliches,
                self.checksRedundancies != checksRedundancies,
                self.checksFillers != checksFillers,
            ].contains(true)

            self.editorFont = editorFont
            self.highlightColor = highlightColor
            self.highlightsNouns = highlightsNouns
            self.highlightsVerbs = highlightsVerbs
            self.highlightsAdjectives = highlightsAdjectives
            self.highlightsAdverbs = highlightsAdverbs
            self.highlightsConjunctions = highlightsConjunctions
            self.checksCliches = checksCliches
            self.checksRedundancies = checksRedundancies
            self.checksFillers = checksFillers
            self.focusScope = focusScope
            self.isFocusMode = isFocusMode
            self.usesTypewriterScrolling = usesTypewriterScrolling
            return didChangeSyntaxConfiguration
        }

        fileprivate func syncScrollRatioIfNeeded(on scrollView: NSScrollView) {
            guard let ratio = scrollRatio(in: scrollView) else { return }
            guard abs(ratio - ownedScrollRatio) > 0.005 else { return }
            ownedScrollRatio = ratio
            syncScrollRatio?.wrappedValue = ratio
        }

        fileprivate func syncScrollPositionIfNeeded(on scrollView: NSScrollView) {
            guard let ratio = syncScrollRatio?.wrappedValue else { return }
            guard abs(ratio - ownedScrollRatio) > 0.005 else { return }
            guard let position = scrollPosition(for: ratio, in: scrollView) else { return }
            ownedScrollRatio = ratio
            let clipView = scrollView.contentView
            clipView.scroll(to: position)
            scrollView.reflectScrolledClipView(clipView)
        }

        private func scrollPosition(for ratio: CGFloat, in scrollView: NSScrollView) -> NSPoint? {
            let clipView = scrollView.contentView
            guard let documentView = scrollView.documentView else { return nil }
            let scrollableH = documentView.frame.height - clipView.bounds.height
            guard scrollableH > 1 else { return nil }
            let targetY = max(0, min(scrollableH, ratio * scrollableH))
            return NSPoint(x: clipView.bounds.minX, y: targetY)
        }

        private func scrollRatio(in scrollView: NSScrollView) -> CGFloat? {
            let clipView = scrollView.contentView
            guard let documentView = scrollView.documentView else { return nil }
            let scrollableH = documentView.frame.height - clipView.bounds.height
            guard scrollableH > 1 else { return nil }
            return max(0, min(1, clipView.bounds.origin.y / scrollableH))
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingExternalChange,
                  !isApplyingSyntaxHighlighting,
                  let textView = notification.object as? NSTextView else {
                return
            }
            text = textView.string
            scheduleSyntaxHighlighting(in: textView)
            scrollToTypewriterPositionIfNeeded(textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateFocusHighlighting(in: textView)
            scrollToTypewriterPositionIfNeeded(textView)
        }

        func applySyntaxHighlighting(to textView: NSTextView) {
            syntaxHighlightTask?.cancel()
            syntaxHighlightTask = nil
            isApplyingSyntaxHighlighting = true
            MarkdownSyntaxHighlighter.clearFocusScope(in: textView)
            updateHeadingGutter(in: textView)
            MarkdownSyntaxHighlighter.apply(
                to: textView,
                fontType: editorFont,
                textColor: MarkdownTextView.editorTextColor(),
                accentColor: NSColor(AppTheme.accentColor),
                highlightColor: highlightColor.nsColor,
                highlightsNouns: highlightsNouns,
                highlightsVerbs: highlightsVerbs,
                highlightsAdjectives: highlightsAdjectives,
                highlightsAdverbs: highlightsAdverbs,
                highlightsConjunctions: highlightsConjunctions,
                checksCliches: checksCliches,
                checksRedundancies: checksRedundancies,
                checksFillers: checksFillers
            )
            updateFocusHighlighting(in: textView)
            isApplyingSyntaxHighlighting = false
        }

        func updateFocusHighlighting(in textView: NSTextView) {
            MarkdownSyntaxHighlighter.clearFocusScope(in: textView)
            guard isFocusMode else { return }
            MarkdownSyntaxHighlighter.applyFocusScope(
                to: textView,
                scope: focusScope,
                caretLocation: textView.selectedRange().location
            )
        }

        private func scheduleSyntaxHighlighting(in textView: NSTextView) {
            syntaxHighlightTask?.cancel()
            syntaxHighlightTask = Task { @MainActor [weak self, weak textView] in
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled, let self, let textView else { return }
                applySyntaxHighlighting(to: textView)
            }
        }

        private func updateHeadingGutter(in textView: NSTextView) {
            let headingGutter = MarkdownSyntaxHighlighter.headingIndent(
                for: editorFont,
                maxLevel: MarkdownSyntaxHighlighter.maxHeadingLevel(in: textView.string)
            )
            (textView as? ColumnTextView)?.markerGutter = headingGutter

            guard let paragraphStyle = textView.defaultParagraphStyle?
                .mutableCopy() as? NSMutableParagraphStyle,
                paragraphStyle.firstLineHeadIndent != headingGutter else {
                return
            }
            paragraphStyle.firstLineHeadIndent = headingGutter
            paragraphStyle.headIndent = headingGutter
            textView.defaultParagraphStyle = paragraphStyle
        }

        private func scrollToTypewriterPositionIfNeeded(_ textView: NSTextView) {
            guard isFocusMode,
                  usesTypewriterScrolling,
                  let scrollView = textView.enclosingScrollView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer,
                  layoutManager.numberOfGlyphs > 0 else {
                return
            }

            layoutManager.ensureLayout(for: textContainer)
            let characterIndex = min(
                textView.selectedRange().location,
                max(0, (textView.string as NSString).length - 1)
            )
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
            var lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex,
                effectiveRange: nil
            )
            lineRect.origin.x += textView.textContainerOrigin.x
            lineRect.origin.y += textView.textContainerOrigin.y

            let clipView = scrollView.contentView
            let maximumY = max(0, textView.bounds.height - clipView.bounds.height)
            let targetY = min(
                maximumY,
                max(0, lineRect.midY - clipView.bounds.height * 0.4)
            )
            clipView.scroll(to: NSPoint(x: clipView.bounds.minX, y: targetY))
            scrollView.reflectScrolledClipView(clipView)
        }
    }
}
