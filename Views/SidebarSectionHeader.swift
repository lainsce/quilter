import SwiftUI

struct SidebarSectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(AppTheme.caption)
            .textCase(.uppercase)
            .kerning(0.8)
            .foregroundStyle(.secondary)
            .padding(.bottom, AppTheme.gridSmallGap)
    }
}
