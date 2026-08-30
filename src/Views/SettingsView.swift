import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences

    var body: some View {
        TabView {
            Tab("Editor", systemImage: "pencil.and.scribble") {
                EditorSettingsView(preferences: preferences)
            }

            Tab("Preview", systemImage: "doc.richtext") {
                PreviewSettingsView(preferences: preferences)
            }

            Tab("Library", systemImage: "internaldrive") {
                LibrarySettingsView(appState: appState, preferences: preferences)
            }
        }
        .background(AppTheme.industrialSurface)
        .frame(width: 500, height: 600)
    }
}
