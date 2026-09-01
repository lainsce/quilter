import SwiftUI

struct SidebarHashtagListView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarSectionHeader(title: "Hashtags")

            if appState.allTags.isEmpty {
                Text("No hashtags")
                    .font(AppTheme.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                TagFilterView(appState: appState)
            }
        }
    }
}
