import SwiftUI

struct LibrarySettingsView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    @State private var libraryVersion = 0
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        NULSettingsPage {
            NULSettingsSection(
                "Library",
                footer: "The default Library is inside Quilter’s sandbox. A selected folder is retained with a macOS security-scoped bookmark."
            ) {
                NULSettingsItem {
                    VStack(alignment: .leading, spacing: AppTheme.gridUnit * 3) {
                        Text(QuilterLibrary.locationDescription)
                            .font(AppTheme.technicalFont(role: .contentBlockSubtitle))
                            .textSelection(.enabled)
                            .id(libraryVersion)

                        HStack {
                            Spacer()
                            Button("Choose Library…") {
                                if QuilterLibrary.chooseFolder() {
                                    libraryVersion += 1
                                }
                            }
                            .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))

                            Button("Reveal in Finder") {
                                QuilterLibrary.revealInFinder()
                            }
                            .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))
                        }
                    }
                }
            }

            NULSettingsSection("Sidebar") {
                NULSettingsItem {
                    NULFormRow("Show Sidebar") {
                        Toggle("", isOn: $appState.isSidebarVisible)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Show Sidebar")
                    }
                }
            }

            NULSettingsSection("Sidebar Sections") {
                NULSettingsItem {
                    NULFormRow("Files") { Toggle("", isOn: $preferences.showsFilesInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Files") }
                }
                NULSettingsItem {
                    NULFormRow("Outline") { Toggle("", isOn: $preferences.showsOutlineInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Outline") }
                }
                NULSettingsItem {
                    NULFormRow("Hashtag list") { Toggle("", isOn: $preferences.showsHashtagsInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Hashtag list") }
                }
            }
        }
    }
}
