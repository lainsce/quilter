import SwiftUI

struct LibrarySettingsView: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    @State private var libraryVersion = 0
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        ScrollView(.vertical) {
            Form {
                Section {
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
                } header: {
                    Text("Library")
                } footer: {
                    Text("The default Library is inside Quilter’s sandbox. A selected folder is retained with a macOS security-scoped bookmark.")
                }

                Section("Sidebar") {
                    NULFormRow("Show Sidebar") {
                        Toggle("", isOn: $appState.isSidebarVisible)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Show Sidebar")
                    }
                }

                Section("Sidebar Sections") {
                    NULFormRow("Files") { Toggle("", isOn: $preferences.showsFilesInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Files") }
                    NULFormRow("Outline") { Toggle("", isOn: $preferences.showsOutlineInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Outline") }
                    NULFormRow("Hashtag list") { Toggle("", isOn: $preferences.showsHashtagsInSidebar).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Hashtag list") }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .background(AppTheme.industrialSurface, in: RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous))
        }
        .scrollIndicators(.automatic)
        .background(AppTheme.industrialSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .defaultScrollAnchor(.top)
        .padding(AppTheme.gridSectionGap)
    }
}
