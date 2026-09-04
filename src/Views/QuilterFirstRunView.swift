import SwiftUI

/// A one-time orientation for Quilter's document and preview workflow.
struct QuilterFirstRunView: View {
    let onCreateDocument: () -> Void
    let onOpenFile: () -> Void
    let onContinue: () -> Void

    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppTheme.gridSmallGap) {
                Text("Quilter")
                    .font(AppTheme.viewTitle)

                Text("A focused space for Markdown.")
                    .font(AppTheme.viewSubtitle)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, AppTheme.gridSectionGap)

            Text("Write locally in the editor, then switch to a split view or preview when you want to read the rendered Markdown.")
                .font(AppTheme.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, AppTheme.gridSectionGap)

            VStack(alignment: .leading, spacing: AppTheme.gridSectionGap) {
                instruction(
                    systemImage: "doc.badge.plus",
                    title: "New Document",
                    detail: "Start an unsaved Markdown document with the toolbar or ⌘N."
                )
                instruction(
                    systemImage: "folder",
                    title: "Open a File…",
                    detail: "Open a Markdown or plain-text file with the toolbar or ⌘O."
                )
                instruction(
                    systemImage: "rectangle.split.2x1",
                    title: "Choose a view",
                    detail: "Use Editor Actions to switch between editor, split, and preview."
                )
            }

            Spacer(minLength: AppTheme.gridSectionGap)

            HStack(spacing: AppTheme.gridSmallGap) {
                Button("Later", action: onContinue)
                    .buttonStyle(NULButtonStyle(kind: .quiet, accentColor: accentColor))

                Spacer(minLength: 0)

                Button("Open File…", action: onOpenFile)
                    .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))

                Button("New Document", action: onCreateDocument)
                    .buttonStyle(NULButtonStyle(kind: .primary, accentColor: accentColor))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppTheme.gridContentInset)
        .background(
            AppTheme.industrialSurface,
            in: RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous)
        )
        .frame(minWidth: 520, idealWidth: 560, minHeight: 420)
        .background(AppTheme.workspaceBackground(for: colorScheme))
    }

    private func instruction(
        systemImage: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: AppTheme.gridSectionGap) {
            Image(systemName: systemImage)
                .font(.system(size: AppTheme.toolbarIconSize, weight: .regular))
                .frame(width: AppTheme.toolbarControlSize, height: AppTheme.toolbarControlSize)
                .background(
                    AppTheme.workspaceBackground(for: colorScheme),
                    in: RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.gridSmallGap) {
                Text(title)
                    .font(AppTheme.contentBlockTitle)

                Text(detail)
                    .font(AppTheme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
