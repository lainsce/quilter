import SwiftUI

struct MarkdownPreviewView: View {
    @Bindable var document: DocumentItem
    @Bindable var preferences: AppPreferences
    var syncScrollRatio: Binding<CGFloat>? = nil

    private let toolbarInset = AppTheme.toolbarInset

    var body: some View {
        GeometryReader { proxy in
            let columnLayout = previewColumnLayout(for: proxy.size.width)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // Fills the toolbar area so the WKWebView frame
                    // (and its scroll indicator) starts below the toolbar.
                    pageBackgroundColor
                        .frame(height: toolbarInset)

                    MarkdownPreviewWebView(
                        markdown: document.text,
                        preferences: preferences,
                        columnLayout: columnLayout,
                        syncScrollRatio: syncScrollRatio
                    )
                    .frame(
                        minWidth: 300,
                        maxWidth: .infinity,
                        minHeight: 300,
                        maxHeight: .infinity
                    )
                }

                // Progressive color fade that starts at the very top (behind the
                // toolbar) and fades into the content below, so the toolbar controls
                // sit over a continuous softer edge.
                ScrollEdgeTreatment(
                    color: pageBackgroundColor,
                    edge: .top,
                    height: toolbarInset + 36
                )
                .frame(maxWidth: .infinity, alignment: .top)
                .ignoresSafeArea(.container, edges: .top)
                .allowsHitTesting(false)

                // Bottom fade behind the document tracker badge.
                if preferences.showsDocumentTracker {
                    VStack(spacing: 0) {
                        Spacer()
                        ScrollEdgeTreatment(
                            color: pageBackgroundColor,
                            edge: .bottom,
                            height: 64
                        )
                    }
                    .allowsHitTesting(false)
                }

                // Window chrome hit-testing layer
                Color.clear
                    .frame(height: toolbarInset)
                    .contentShape(Rectangle())
                    .gesture(WindowDragGesture())
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func previewColumnLayout(for availableWidth: CGFloat) -> MarkdownColumnLayout {
        let editorFont = preferences.editorFont.font(ofSize: AppTheme.editorFontPointSize)
        let targetTextWidth = MarkdownColumnLayout.textWidth(
            font: editorFont,
            characterCount: preferences.columnCharacterCount
        )
        let markerGutter = MarkdownSyntaxHighlighter.headingIndent(
            for: preferences.editorFont,
            maxLevel: MarkdownSyntaxHighlighter.maxHeadingLevel(in: document.text)
        )

        return MarkdownColumnLayout(
            availableWidth: availableWidth,
            targetTextWidth: targetTextWidth,
            markerGutter: markerGutter
        )
    }

    private var pageBackgroundColor: Color {
        Color(nsColor: AppTheme.configuredPreviewSurfaceColor())
    }
}
