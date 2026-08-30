import SwiftUI

struct CheatsheetHeader: View {
    let closeAction: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.gridUnit) {
                Text("Markdown Cheatsheet")
                    .font(AppTheme.contentBlockTitle)
                    .kerning(0.25)
                Text("Type the syntax on the left to produce the result on the right.")
                    .font(AppTheme.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Close", systemImage: "xmark.circle.fill", action: closeAction)
                .labelStyle(.iconOnly)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
                .help("Close")
        }
        .padding(AppTheme.gridUnit * 5)
        .background(AppTheme.industrialSurface)
    }
}
