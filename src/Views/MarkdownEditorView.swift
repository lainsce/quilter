import SwiftUI

struct MarkdownEditorView: View {
    @Bindable var document: DocumentItem
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    var syncScrollRatio: Binding<CGFloat>? = nil

    private let toolbarInset = AppTheme.toolbarInset

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Fills the toolbar area so the NSScrollView frame
                // (and its scroll indicator) starts below the toolbar.
                editorBackgroundColor
                    .frame(height: toolbarInset)

                MarkdownTextView(
                    text: $document.text,
                    scrollTarget: document.scrollTarget,
                    isFocusMode: appState.isFocusMode,
                    preferences: preferences,
                    syncScrollRatio: syncScrollRatio
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: document.text) { _, _ in
                    appState.scheduleAutosave(for: document)
                }
            }

            // Progressive color fade that starts at the very top (behind the
            // toolbar) and fades into the content below, so the toolbar controls
            // sit over a continuous softer edge.
            ScrollEdgeTreatment(
                color: editorBackgroundColor,
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
                        color: editorBackgroundColor,
                        edge: .bottom,
                        height: 64
                    )
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var editorBackgroundColor: Color {
        Color(nsColor: AppTheme.configuredEditorSurfaceColor())
    }
}
