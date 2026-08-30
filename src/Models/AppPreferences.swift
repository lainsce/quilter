import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    static let autosaveDelay = Duration.seconds(30)

    private enum Key {
        static let editorFont = "Quilter.Preferences.EditorFont"
        static let columnCharacterCount = "Quilter.Preferences.ColumnCharacterCount"
        static let highlightColor = "Quilter.Preferences.HighlightColor"
        static let autosave = "Quilter.Preferences.Autosave"
        static let focusScope = "Quilter.Preferences.FocusScope"
        static let typewriterScrolling = "Quilter.Preferences.TypewriterScrolling"
        static let documentTracker = "Quilter.Preferences.DocumentTracker"
        static let speechNouns = "Quilter.Preferences.SpeechParts.Nouns"
        static let speechVerbs = "Quilter.Preferences.SpeechParts.Verbs"
        static let speechAdjectives = "Quilter.Preferences.SpeechParts.Adjectives"
        static let speechAdverbs = "Quilter.Preferences.SpeechParts.Adverbs"
        static let speechConjunctions = "Quilter.Preferences.SpeechParts.Conjunctions"
        static let styleCheckerCliches = "Quilter.Preferences.StyleChecker.Cliches"
        static let styleCheckerRedundancies = "Quilter.Preferences.StyleChecker.Redundancies"
        static let styleCheckerFillers = "Quilter.Preferences.StyleChecker.Fillers"
        static let previewFont = "Quilter.Preferences.PreviewFont"
        static let centersHeaders = "Quilter.Preferences.CentersHeaders"
        static let codeHighlighting = "Quilter.Preferences.CodeHighlighting"
        static let latexMath = "Quilter.Preferences.LaTeXMath"
        static let mermaidGraphs = "Quilter.Preferences.MermaidGraphs"
        static let toolbarVisibility = "Quilter.Preferences.ToolbarVisibility"
        static let showsFilesInSidebar = "Quilter.Preferences.Library.Sidebar.Files"
        static let showsOutlineInSidebar = "Quilter.Preferences.Library.Sidebar.Outline"
        static let showsHashtagsInSidebar = "Quilter.Preferences.Library.Sidebar.Hashtags"
    }

    var editorFont: EditorFontType {
        didSet { defaults.set(editorFont.rawValue, forKey: Key.editorFont) }
    }
    var columnCharacterCount: Int {
        didSet { defaults.set(columnCharacterCount, forKey: Key.columnCharacterCount) }
    }
    var highlightColor: MarkdownHighlightColor {
        didSet { defaults.set(highlightColor.rawValue, forKey: Key.highlightColor) }
    }
    var autosave: Bool {
        didSet { defaults.set(autosave, forKey: Key.autosave) }
    }
    var focusScope: FocusScope {
        didSet { defaults.set(focusScope.rawValue, forKey: Key.focusScope) }
    }
    var typewriterScrolling: Bool {
        didSet { defaults.set(typewriterScrolling, forKey: Key.typewriterScrolling) }
    }
    var showsDocumentTracker: Bool {
        didSet { defaults.set(showsDocumentTracker, forKey: Key.documentTracker) }
    }
    var highlightsNouns: Bool {
        didSet { defaults.set(highlightsNouns, forKey: Key.speechNouns) }
    }
    var highlightsVerbs: Bool {
        didSet { defaults.set(highlightsVerbs, forKey: Key.speechVerbs) }
    }
    var highlightsAdjectives: Bool {
        didSet { defaults.set(highlightsAdjectives, forKey: Key.speechAdjectives) }
    }
    var highlightsAdverbs: Bool {
        didSet { defaults.set(highlightsAdverbs, forKey: Key.speechAdverbs) }
    }
    var highlightsConjunctions: Bool {
        didSet { defaults.set(highlightsConjunctions, forKey: Key.speechConjunctions) }
    }
    var checksCliches: Bool {
        didSet { defaults.set(checksCliches, forKey: Key.styleCheckerCliches) }
    }
    var checksRedundancies: Bool {
        didSet { defaults.set(checksRedundancies, forKey: Key.styleCheckerRedundancies) }
    }
    var checksFillers: Bool {
        didSet { defaults.set(checksFillers, forKey: Key.styleCheckerFillers) }
    }
    var previewFont: PreviewFontType {
        didSet { defaults.set(previewFont.rawValue, forKey: Key.previewFont) }
    }
    var centersPreviewHeaders: Bool {
        didSet { defaults.set(centersPreviewHeaders, forKey: Key.centersHeaders) }
    }
    var highlightsPreviewCode: Bool {
        didSet { defaults.set(highlightsPreviewCode, forKey: Key.codeHighlighting) }
    }
    var rendersLaTeXMath: Bool {
        didSet { defaults.set(rendersLaTeXMath, forKey: Key.latexMath) }
    }
    var rendersMermaidGraphs: Bool {
        didSet { defaults.set(rendersMermaidGraphs, forKey: Key.mermaidGraphs) }
    }
    var toolbarVisibility: ToolbarVisibilityMode {
        didSet { defaults.set(toolbarVisibility.rawValue, forKey: Key.toolbarVisibility) }
    }
    var showsFilesInSidebar: Bool {
        didSet { defaults.set(showsFilesInSidebar, forKey: Key.showsFilesInSidebar) }
    }
    var showsOutlineInSidebar: Bool {
        didSet { defaults.set(showsOutlineInSidebar, forKey: Key.showsOutlineInSidebar) }
    }
    var showsHashtagsInSidebar: Bool {
        didSet { defaults.set(showsHashtagsInSidebar, forKey: Key.showsHashtagsInSidebar) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.editorFont: EditorFontType.quiltMono.rawValue,
            Key.columnCharacterCount: 64,
            Key.highlightColor: MarkdownHighlightColor.yellow.rawValue,
            Key.autosave: true,
            Key.focusScope: FocusScope.paragraph.rawValue,
            Key.typewriterScrolling: false,
            Key.documentTracker: true,
            Key.speechNouns: false,
            Key.speechVerbs: false,
            Key.speechAdjectives: false,
            Key.speechAdverbs: false,
            Key.speechConjunctions: false,
            Key.styleCheckerCliches: false,
            Key.styleCheckerRedundancies: false,
            Key.styleCheckerFillers: false,
            Key.previewFont: PreviewFontType.serif.rawValue,
            Key.centersHeaders: false,
            Key.codeHighlighting: true,
            Key.latexMath: true,
            Key.mermaidGraphs: false,
            Key.toolbarVisibility: ToolbarVisibilityMode.hover.rawValue,
            Key.showsFilesInSidebar: true,
            Key.showsOutlineInSidebar: true,
            Key.showsHashtagsInSidebar: false
        ])

        editorFont = EditorFontType(
            rawValue: defaults.string(forKey: Key.editorFont) ?? ""
        ) ?? .quiltMono
        columnCharacterCount = defaults.integer(forKey: Key.columnCharacterCount)
        highlightColor = MarkdownHighlightColor(
            rawValue: defaults.string(forKey: Key.highlightColor) ?? ""
        ) ?? .yellow
        autosave = defaults.bool(forKey: Key.autosave)
        focusScope = FocusScope(
            rawValue: defaults.string(forKey: Key.focusScope) ?? ""
        ) ?? .paragraph
        typewriterScrolling = defaults.bool(forKey: Key.typewriterScrolling)
        showsDocumentTracker = defaults.bool(forKey: Key.documentTracker)
        highlightsNouns = defaults.bool(forKey: Key.speechNouns)
        highlightsVerbs = defaults.bool(forKey: Key.speechVerbs)
        highlightsAdjectives = defaults.bool(forKey: Key.speechAdjectives)
        highlightsAdverbs = defaults.bool(forKey: Key.speechAdverbs)
        highlightsConjunctions = defaults.bool(forKey: Key.speechConjunctions)
        checksCliches = defaults.bool(forKey: Key.styleCheckerCliches)
        checksRedundancies = defaults.bool(forKey: Key.styleCheckerRedundancies)
        checksFillers = defaults.bool(forKey: Key.styleCheckerFillers)
        previewFont = PreviewFontType(
            rawValue: defaults.string(forKey: Key.previewFont) ?? ""
        ) ?? .serif
        centersPreviewHeaders = defaults.bool(forKey: Key.centersHeaders)
        highlightsPreviewCode = defaults.bool(forKey: Key.codeHighlighting)
        rendersLaTeXMath = defaults.bool(forKey: Key.latexMath)
        rendersMermaidGraphs = defaults.bool(forKey: Key.mermaidGraphs)
        toolbarVisibility = ToolbarVisibilityMode(
            rawValue: defaults.string(forKey: Key.toolbarVisibility) ?? ""
        ) ?? .hover
        showsFilesInSidebar = defaults.bool(forKey: Key.showsFilesInSidebar)
        showsOutlineInSidebar = defaults.bool(forKey: Key.showsOutlineInSidebar)
        showsHashtagsInSidebar = defaults.bool(forKey: Key.showsHashtagsInSidebar)
    }
}
