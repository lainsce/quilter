#if os(macOS)
import AppKit
import SwiftUI

struct QuilterAboutView: View {
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.gridSectionGap) {
            appIcon

            VStack(spacing: AppTheme.gridUnit * 2) {
                Text("Quilter")
                    .font(AppTheme.viewTitle)
                    .tracking(-0.4)

                Text("A focused space for Markdown.")
                    .font(AppTheme.viewSubtitle)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                Text("Write, organize, and preview Markdown")
                Text("locally in a native Mac editor.")
            }
            .font(AppTheme.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: 320)

            HStack(spacing: AppTheme.gridUnit * 4) {
                AboutCapability(title: "Native editor", systemImage: "text.cursor")
                AboutCapability(title: "Live preview", systemImage: "rectangle.split.2x1")
                AboutCapability(title: "Local-first", systemImage: "internaldrive")
            }
            .font(AppTheme.caption)
            .foregroundStyle(.secondary)

            Rectangle()
                .fill(AppTheme.industrialQuietRule(for: colorScheme))
                .frame(height: AppTheme.delimiterThickness)
                .padding(.vertical, AppTheme.gridUnit)

            VStack(spacing: AppTheme.gridUnit) {
                Text("Version \(versionString)")
                    .font(AppTheme.technicalFont(role: .caption))
                    .foregroundStyle(.secondary)

                Text("Made with SwiftUI and AppKit for Mac.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.tertiary)

                Text("Copyright © 2026 Quilter contributors.")
                    .font(AppTheme.micro)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Spacer(minLength: 0)

                Button("Done") {
                    dismissWindow(id: QuilterWindowID.about)
                }
                .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppTheme.gridContentInset)
        .frame(width: 440)
        .background(AppTheme.industrialSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accentColor)
                .frame(height: 3)
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = NSApplication.shared.applicationIconImage {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.industrialQuietRule(for: colorScheme), lineWidth: 1)
                }
                .accessibilityHidden(true)
        } else {
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(accentColor)
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)
        }
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "1"
        return "\(version) (\(build))"
    }
}

private struct AboutCapability: View {
    let title: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
    }
}
#endif
