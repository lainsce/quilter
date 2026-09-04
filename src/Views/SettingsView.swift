import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences

    private enum SettingsTab: Hashable, CaseIterable {
        case editor
        case preview
        case library

        var title: LocalizedStringKey {
            switch self {
            case .editor: "Editor"
            case .preview: "Preview"
            case .library: "Library"
            }
        }
    }

    @State private var selectedTab: SettingsTab = .editor

    var body: some View {
        NULSettingsWindow {
            VStack(alignment: .leading, spacing: 0) {
                NULTabBar(
                    selection: $selectedTab,
                    options: SettingsTab.allCases
                ) { tab in
                    Text(tab.title)
                }
                .padding(.horizontal, AppTheme.settingsWindowInset)

                Group {
                    switch selectedTab {
                    case .editor:
                        EditorSettingsView(preferences: preferences)
                    case .preview:
                        PreviewSettingsView(preferences: preferences)
                    case .library:
                        LibrarySettingsView(appState: appState, preferences: preferences)
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}
