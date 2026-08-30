import SwiftUI

struct AppWindowView: View {
    static let sidebarMinimumWidth: CGFloat = 300
    static let sidebarIdealWidth: CGFloat = 300
    static let sidebarMaximumWidth: CGFloat = 300
    static let toolbarClearance: CGFloat = AppTheme.toolbarInset
    private static let minimumEditorWidth: CGFloat = 500

    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(appState: appState, preferences: preferences)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .ignoresSafeArea(.container, edges: .top)
                .toolbar(removing: .sidebarToggle)
                .navigationSplitViewColumnWidth(
                    min: Self.sidebarMinimumWidth,
                    ideal: Self.sidebarIdealWidth,
                    max: Self.sidebarMaximumWidth
                )
        } detail: {
            // EditorPaneView owns AppKit/WKWebView scroll surfaces and draws
            // the edge treatment itself. Applying SwiftUI's scroll-edge
            // transform to this wrapper adds a safe-area offset to the
            // container instead of the actual scroll view.
            EditorPaneView(
                appState: appState,
                preferences: preferences
            )
            .frame(
                minWidth: Self.minimumEditorWidth,
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .ignoresSafeArea(.container, edges: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.workspaceBackground(for: colorScheme))
        .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: columnVisibility)
        .dropDestination(for: URL.self) { urls, _ in
            _ = appState.open(urls: urls)
        }
        .onOpenURL { url in
            _ = appState.open(urls: [url])
        }
        .alert(
            appState.presentedError?.title ?? "Error",
            item: $appState.presentedError
        ) { _ in
            Button("OK") { }
        } message: { error in
            Text(error.message)
        }
        .onAppear {
            columnVisibility = appState.isFocusMode || !appState.isSidebarVisible
                ? .detailOnly
                : .all
        }
        .onChange(of: columnVisibility) { _, visibility in
            guard !appState.isFocusMode else { return }
            let isVisible = visibility != .detailOnly
            if isVisible != appState.isSidebarVisible {
                // Keep normal-mode visibility controlled by the Library setting.
                // Native split-view actions cannot collapse the sidebar behind it.
                columnVisibility = appState.isSidebarVisible ? .all : .detailOnly
            }
        }
        .onChange(of: appState.isSidebarVisible) { _, isVisible in
            guard !appState.isFocusMode else { return }
            columnVisibility = isVisible ? .all : .detailOnly
        }
        .onChange(of: appState.isFocusMode) { _, isFocusMode in
            columnVisibility = isFocusMode || !appState.isSidebarVisible
                ? .detailOnly
                : .all
        }
    }
}
