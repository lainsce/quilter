import SwiftUI

struct EditorPaneView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    @Environment(WindowChromeState.self) private var chromeState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var splitRatio: CGFloat = 0.5
    @GestureState private var dividerDragOffset: CGFloat = 0
    @State private var syncScrollRatio: CGFloat = 0

    var body: some View {
        Group {
            if let document = appState.selectedDocument {
                switch appState.editorLayout {
                case .editorOnly:
                    MarkdownEditorView(
                        document: document,
                        appState: appState,
                        preferences: preferences
                    )
                    .id(document.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .split:
                    splitView(for: document)
                case .previewOnly:
                    MarkdownPreviewView(
                        document: document,
                        preferences: preferences
                    )
                    .id(document.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                EmptyEditorView(openAction: appState.showOpenPanel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paneBackground)
        .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: appState.isFocusMode)
        .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: appState.editorLayout)
        .overlay(alignment: .bottomTrailing) {
            if preferences.showsDocumentTracker,
               let document = appState.selectedDocument {
                EditorStatusBadge(document: document)
                    .padding(.trailing, AppTheme.gridGutter)
                    .padding(.bottom, AppTheme.gridGutter)
            }
        }
        .overlay(alignment: .topLeading) {
            if !appState.isFocusMode {
                ActiveDocumentTitle(appState: appState)
                .padding(.leading, AppTheme.gridGutter)
                .frame(height: AppWindowView.toolbarClearance, alignment: .center)
                .opacity(chromeState.isVisible ? 1 : 0)
                .allowsHitTesting(chromeState.isVisible)
                .accessibilityHidden(!chromeState.isVisible)
                .animation(
                    reduceMotion ? nil : AppTheme.interfaceSpring,
                    value: chromeState.isVisible
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Spacer()
            }
            .sharedBackgroundVisibility(.hidden)

            if appState.isFocusMode {
                ToolbarItem(placement: .primaryAction) {
                    FocusModeExitButton(action: appState.exitFocusMode)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 0) {
                        if !preferences.autosave {
                            Button("Save", systemImage: "arrow.down.to.line", action: appState.saveSelected)
                                .labelStyle(.iconOnly)
                                .buttonStyle(NULToolbarButtonStyle(showsSurface: false))
                                .disabled(appState.selectedDocument == nil)
                                .help("Save (⌘S)")
                        }

                        EditorHighlightsMenu(
                            appState: appState,
                            preferences: preferences,
                            showsSurface: false
                        )
                    }
                    .frame(height: AppTheme.toolbarControlSize)
                    .background(
                        AppTheme.industrialPanel,
                        in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
                    )
                    .opacity(chromeState.isVisible ? 1 : 0)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarSpacer(.fixed)
                    .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .primaryAction) {
                    EditorActionsMenu(appState: appState)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private func editorColumnWidth(for totalWidth: CGFloat) -> CGFloat {
        let baseWidth = totalWidth * splitRatio
        return max(300, min(totalWidth - 301, baseWidth + dividerDragOffset))
    }

    @ViewBuilder
    private func splitView(for document: DocumentItem) -> some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let baseWidth = totalWidth * splitRatio
            let editorWidth = editorColumnWidth(for: totalWidth)

            HStack(spacing: 0) {
                MarkdownEditorView(
                    document: document,
                    appState: appState,
                    preferences: preferences,
                    syncScrollRatio: $syncScrollRatio
                )
                .frame(width: editorWidth)

                splitDivider(totalWidth: totalWidth, baseWidth: baseWidth)

                MarkdownPreviewView(
                    document: document,
                    preferences: preferences,
                    syncScrollRatio: $syncScrollRatio
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .id(document.id)
        .onChange(of: document.id) { syncScrollRatio = 0 }
    }

    @ViewBuilder
    private func splitDivider(totalWidth: CGFloat, baseWidth: CGFloat) -> some View {
        Rectangle()
            .fill(editorSurface)
            .frame(width: AppTheme.delimiterThickness)
            .overlay {
                Color.clear
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($dividerDragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let newWidth = max(300, min(totalWidth - 301, baseWidth + value.translation.width))
                                let newRatio = newWidth / totalWidth
                                withAnimation(reduceMotion ? nil : AppTheme.interfaceSpring) {
                                    splitRatio = newRatio
                                }
                            }
                    )
            }
    }

    private var editorSurface: Color {
        Color(nsColor: AppTheme.configuredEditorSurfaceColor())
    }

    private var previewSurface: Color {
        Color(nsColor: AppTheme.configuredPreviewSurfaceColor())
    }

    private var paneBackground: Color {
        appState.editorLayout == .previewOnly ? previewSurface : editorSurface
    }
}
