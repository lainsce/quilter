import SwiftUI

struct OpenControl: View {
    @Bindable var appState: AppState
    @Environment(WindowChromeState.self) private var chromeState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Button(action: appState.showOpenPanel) {
                NULIcon(systemImage: "folder")
                    .frame(width: AppTheme.toolbarControlSize, height: AppTheme.toolbarControlSize)
            }
            .buttonStyle(.plain)
            .contentShape(.rect(cornerRadius: AppTheme.industrialCornerRadius))
            .accessibilityLabel("Open")
            .help("Open Files (⌘O)")

            Rectangle()
                .fill(AppTheme.industrialControlRule(for: colorScheme))
                .frame(width: 1, height: 18)

            Menu {
                if !appState.recentFileURLs.isEmpty {
                    Rectangle()
                        .fill(AppTheme.industrialControlRule(for: colorScheme))
                        .frame(height: AppTheme.delimiterThickness)
                    Section("Recent Files") {
                        ForEach(appState.recentFileURLs, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                appState.open(urls: [url])
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
                    .frame(width: AppTheme.toolbarControlSize, height: AppTheme.toolbarControlSize)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .contentShape(.rect(cornerRadius: AppTheme.industrialCornerRadius))
            .accessibilityLabel("Open options")
            .help("Open Recent")
        }
        .frame(width: 70, height: AppTheme.toolbarControlSize)
        .nulToolbarControlSurface(
            isVisible: chromeState.isVisible
        )
        .fixedSize()
    }
}
