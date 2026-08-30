import SwiftUI

struct OutlineRow: View {
    let heading: HeadingItem
    let action: () -> Void
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.gridUnit * 2) {
                Text(String(repeating: "#", count: heading.level))
                    .font(AppTheme.technicalFont(role: .caption))
                    .foregroundStyle(.secondary)

                Text(heading.title)
                    .font(AppTheme.body)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.vertical, AppTheme.gridUnit * 2)
            .padding(.leading, CGFloat(heading.level - 1) * AppTheme.gridUnit * 3)
            .padding(.horizontal, AppTheme.gridUnit * 2)
            .background(
                isHovering ? AppTheme.sidebarHoverFill(for: colorScheme) : .clear,
                in: .rect(cornerRadius: AppTheme.industrialSmallCornerRadius)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help("Go to \(heading.title)")
        .accessibilityLabel("Level \(heading.level) heading, \(heading.title)")
    }
}
