import SwiftUI

struct SidebarView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    @Environment(WindowChromeState.self) private var chromeState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if preferences.showsFilesInSidebar {
                        SidebarSectionHeader(title: "Files")

                        if appState.openDocuments.isEmpty {
                            SidebarEmptyFilesView(openAction: appState.showOpenPanel)
                        } else {
                            OpenDocumentsList(appState: appState)
                        }
                    }

                    if preferences.showsOutlineInSidebar {
                        OutlineView(document: appState.selectedDocument)
                            .padding(.top, AppTheme.sidebarSectionSpacing)
                    }

                    if preferences.showsHashtagsInSidebar {
                        SidebarHashtagListView(appState: appState)
                            .padding(.top, AppTheme.sidebarSectionSpacing)
                    }
                }
                .padding(.horizontal, AppTheme.sidebarHorizontalPadding)
                .padding(.top, AppWindowView.toolbarClearance)
                .padding(.bottom, AppTheme.gridUnit * 5)
            }

            sidebarToolbarControls
                .padding(.top, AppTheme.gridSmallGap)
                .padding(.leading, AppTheme.toolbarLeadingInset)
                .opacity(chromeState.isVisible ? 1 : 0)
                .allowsHitTesting(chromeState.isVisible)
                .accessibilityHidden(!chromeState.isVisible)
                .animation(
                    reduceMotion ? nil : AppTheme.interfaceSpring,
                    value: chromeState.isVisible
                )
                .zIndex(1)
        }
        .scrollContentBackground(.hidden)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(NULSidebarSurface())
        .accessibilityLabel("Document Sidebar")
        .onChange(of: preferences.showsHashtagsInSidebar) { _, isVisible in
            if !isVisible {
                appState.selectedTag = nil
            }
        }
    }

    private var sidebarToolbarControls: some View {
        HStack(spacing: AppTheme.gridSmallGap) {
            Button("New Document", systemImage: "plus", action: appState.newDocument)
                .buttonStyle(NULToolbarButtonStyle())
                .labelStyle(.iconOnly)
                .help("New Document")

            OpenControl(appState: appState)
        }
    }
}


