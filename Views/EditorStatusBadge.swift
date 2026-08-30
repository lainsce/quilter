import SwiftUI

struct EditorStatusBadge: View {
    let document: DocumentItem
    @AppStorage(EditorStatusMetric.selectionDefaultsKey)
    private var selectedMetricRawValue = EditorStatusMetric.sentences.rawValue

    private var selectedMetric: EditorStatusMetric {
        EditorStatusMetric(rawValue: selectedMetricRawValue) ?? .sentences
    }

    var body: some View {
        Menu {
            Picker("Editor Statistic", selection: $selectedMetricRawValue) {
                ForEach(EditorStatusMetric.allCases) { metric in
                    Label(metric.title, systemImage: metric.systemImage)
                        .tag(metric.rawValue)
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: AppTheme.gridUnit * 2) {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(selectedMetric.displayText(for: document))
                    .foregroundStyle(.primary)
            }
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .fixedSize()
        .font(AppTheme.caption)
        .padding(.horizontal, AppTheme.gridUnit * 3)
        .frame(minHeight: AppTheme.gridUnit * 8)
        .contentShape(.rect(cornerRadius: AppTheme.industrialCornerRadius))
        // This tracker lives over editor content, so it should remain a flat
        // content-layer badge rather than becoming another glass surface.
        .background(
            AppTheme.industrialSurface,
            in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
        )
        .help("Choose Editor Statistic")
        .accessibilityLabel("Editor statistic")
        .accessibilityValue(Text(selectedMetric.displayText(for: document)))
    }
}
