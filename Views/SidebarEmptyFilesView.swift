import SwiftUI

struct SidebarEmptyFilesView: View {
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No open files")
                .font(AppTheme.body)
                .foregroundStyle(.secondary)

            Button("Open a File…", action: openAction)
                .buttonStyle(.link)
        }
        .padding(.vertical, AppTheme.gridUnit * 3)
    }
}
