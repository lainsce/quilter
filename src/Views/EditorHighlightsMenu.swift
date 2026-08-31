import SwiftUI

struct EditorHighlightsMenu: View {
    @Bindable var appState: AppState
    @Bindable var preferences: AppPreferences
    var showsSurface: Bool = true
    @Environment(WindowChromeState.self) private var chromeState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isControlHovered = false

    var body: some View {
        HStack(spacing: AppTheme.gridUnit * 2) {
            Button {
                appState.isFocusMode.toggle()
            } label: {
                Label("Focus Mode", systemImage: "viewfinder")
                    .symbolVariant(appState.isFocusMode ? .fill : .none)
                    .font(.system(size: 16, weight: .regular))
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.primary)
                    .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
            }
            .frame(width: AppTheme.toolbarControlSize, height: AppTheme.toolbarControlSize)
            .buttonStyle(.plain)
            .disabled(appState.selectedDocument == nil)
            .help("Focus Mode")

            Rectangle()
                .fill(AppTheme.industrialControlRule(for: colorScheme))
                .frame(width: 1, height: 18)
                .opacity(isControlHovered ? 0 : 1)

            Menu {
                Section("Speech Parts") {
                    Toggle("Nouns", isOn: $preferences.highlightsNouns)
                    Toggle("Verbs", isOn: $preferences.highlightsVerbs)
                    Toggle("Adjectives", isOn: $preferences.highlightsAdjectives)
                    Toggle("Adverbs", isOn: $preferences.highlightsAdverbs)
                    Toggle("Conjunctions", isOn: $preferences.highlightsConjunctions)
                }

                Rectangle()
                    .fill(AppTheme.industrialControlRule(for: colorScheme))
                    .frame(height: AppTheme.delimiterThickness)

                Section("Writing Focus") {
                    Toggle("Clichés", isOn: $preferences.checksCliches)
                    Toggle("Redundancies", isOn: $preferences.checksRedundancies)
                    Toggle("Fillers", isOn: $preferences.checksFillers)
                }
            } label: {
                HStack(spacing: AppTheme.gridUnit) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 16, weight: .regular))
                        .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
                }
                .foregroundStyle(.primary)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .help("Speech Parts and Writing Focus")
        }
        .frame(width: 100, height: AppTheme.toolbarControlSize)
        .background {
            if showsSurface {
                RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius)
                    .fill(AppTheme.industrialPanel)
            }
        }
        .opacity(chromeState.isVisible ? 1 : 0)
        .fixedSize()
        .onHover { isControlHovered = $0 }
        .nulWindowActivityAppearance()
    }
}
