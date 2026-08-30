import SwiftUI

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var differentiateWithoutColor
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected && differentiateWithoutColor {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }

                Text(verbatim: "#\(tag)")
                    .lineLimit(1)
            }
            .font(AppTheme.caption)
            .padding(.horizontal, AppTheme.gridUnit * 2)
            .padding(.vertical, AppTheme.gridUnit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                rowFill,
                in: .rect(cornerRadius: AppTheme.industrialSmallCornerRadius)
            )
            .foregroundStyle(Color.primary)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.industrialSmallCornerRadius)
                    .stroke(
                        isSelected && isHovering
                            ? accentColor.opacity(AppTheme.sidebarSelectedBorderOpacity)
                            : .clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(QuilterSidebarRowButtonStyle())
        .onHover { isHovering = $0 }
        .animation(
            reduceMotion ? nil : AppTheme.interfaceSpring,
            value: isHovering
        )
        .help(Text(helpText))
        .accessibilityLabel(Text(verbatim: "#\(tag)"))
        .accessibilityValue(Text(selectionAccessibilityValue))
    }

    private var helpText: LocalizedStringResource {
        isSelected ? "Clear tag filter" : "Filter by #\(tag)"
    }

    private var selectionAccessibilityValue: LocalizedStringResource {
        isSelected ? "Selected" : "Not selected"
    }

    private var rowFill: Color {
        if isSelected {
            return accentColor.opacity(AppTheme.sidebarSelectedFillOpacity)
        }
        if isHovering {
            return AppTheme.sidebarHoverFill(for: colorScheme)
        }
        return .clear
    }
}
