import SwiftUI

struct PrivacyPolicyView: View {
    private enum Tab: Hashable {
        case privacy
        case legal

        var title: String {
            switch self {
            case .privacy: return String(localized: "Privacy Policy")
            case .legal: return String(localized: "Legal Notices")
            }
        }
    }

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Tab = .privacy

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                privacyContent
                    .tag(Tab.privacy)
                    .tabItem {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                    }

                LegalNoticesView()
                    .tag(Tab.legal)
                    .tabItem {
                        Label("Legal Notices", systemImage: "doc.text.fill")
                    }
            }
            .navigationTitle(selectedTab.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismissWindow(id: "privacy-policy")
                    }
                    .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .frame(minWidth: 620, minHeight: 560)
        .background(AppTheme.workspaceBackground(for: colorScheme))
    }

    private var privacyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.gridSectionGap) {
                VStack(alignment: .leading, spacing: AppTheme.gridSmallGap) {
                    Label("Your data stays local", systemImage: "lock.shield.fill")
                        .font(AppTheme.viewTitle)
                    Text("Quilter is a local-first Markdown editor. This policy explains what happens when you use the app.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Rectangle()
                    .fill(AppTheme.industrialControlRule(for: colorScheme))
                    .frame(height: AppTheme.delimiterThickness)

                VStack(alignment: .leading, spacing: AppTheme.gridUnit * 5) {
                    PrivacyPolicySection(
                        title: "Data stored on this Mac",
                        systemImage: "internaldrive",
                        text: "Your documents, editor preferences, recent files, and open-document state are stored locally on this Mac. Quilter does not require an account or cloud sync."
                    )
                    PrivacyPolicySection(
                        title: "Files you choose",
                        systemImage: "doc",
                        text: "When you open a Markdown file or choose a Library folder, Quilter reads only the location you select. macOS access is remembered with a security-scoped bookmark, and Quilter does not upload your files."
                    )
                    PrivacyPolicySection(
                        title: "Preview links",
                        systemImage: "safari",
                        text: "The Markdown preview uses resources bundled with Quilter. When you activate a web link, Quilter hands it to your default browser; the browser’s own privacy practices then apply."
                    )
                    PrivacyPolicySection(
                        title: "No tracking or ads",
                        systemImage: "eye.slash",
                        text: "Quilter does not use advertising, analytics, tracking, diagnostics collection, or third-party account services."
                    )
                    PrivacyPolicySection(
                        title: "Your choices",
                        systemImage: "slider.horizontal.3",
                        text: "You choose which files and Library folders Quilter can access. You can clear recent documents, close documents, and remove local files using the standard macOS controls."
                    )
                }

                Text("Last updated: August 9, 2026")
                    .font(AppTheme.technicalFont(role: .caption))
                    .foregroundStyle(.secondary)
            }
            .padding(AppTheme.gridContentInset)
            .frame(maxWidth: 680, alignment: .leading)
        }
        .background(AppTheme.industrialSurface)
    }
}
