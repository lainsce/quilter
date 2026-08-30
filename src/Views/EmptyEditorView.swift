import SwiftUI

struct EmptyEditorView: View {
    let openAction: () -> Void
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        ContentUnavailableView {
            Label("No Document Selected", systemImage: "doc.text")
                .font(AppTheme.viewTitle)
        } description: {
            Text("Open a Markdown or plain-text file to begin editing.")
                .font(AppTheme.body)
        } actions: {
            Button("Open File…", action: openAction)
                .buttonStyle(NULButtonStyle(kind: .primary, accentColor: accentColor))
                .keyboardShortcut("o", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
