import SwiftUI

/// A reference flyover that pairs Markdown syntax with its rendered effect.
struct CheatsheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            CheatsheetHeader(closeAction: close)

            Rectangle()
                .fill(AppTheme.industrialControlRule(for: colorScheme))
                .frame(height: AppTheme.delimiterThickness)

            ScrollView {
                Grid(alignment: .topLeading, horizontalSpacing: AppTheme.gridSectionGap, verticalSpacing: 0) {
                    ForEach(CheatsheetEntry.allCases.enumerated(), id: \.element.id) { index, entry in
                        GridRow {
                            Text(verbatim: entry.syntax)
                                .font(AppTheme.technicalFont(role: .contentBlockSubtitle))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            CheatsheetEffectView(entry: entry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, AppTheme.gridUnit * 3)

                        if index != CheatsheetEntry.allCases.count - 1 {
                            Rectangle()
                                .fill(AppTheme.industrialControlRule(for: colorScheme))
                                .frame(height: AppTheme.delimiterThickness)
                                .gridCellColumns(2)
                        }
                    }
                }
                .padding(AppTheme.gridSectionGap)
            }
        }
        .frame(width: 560, height: 560)
        .background(AppTheme.industrialSurface)
        .font(AppTheme.body)
    }

    private func close() {
        dismiss()
    }
}

#Preview {
    CheatsheetView()
}
