import SwiftUI

struct RenameDocumentPopover: View {
    let currentFilename: String
    let renameAction: (String) -> Bool
    let cancelAction: () -> Void

    @State private var filename: String
    @FocusState private var isFilenameFocused: Bool
    @Environment(\.appAccentColor) private var accentColor

    init(
        currentFilename: String,
        renameAction: @escaping (String) -> Bool,
        cancelAction: @escaping () -> Void
    ) {
        self.currentFilename = currentFilename
        self.renameAction = renameAction
        self.cancelAction = cancelAction
        _filename = State(initialValue: currentFilename)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Document")
                .font(AppTheme.contentBlockTitle)

            TextField("Filename", text: $filename)
                .textFieldStyle(.plain)
                .textFieldStyle(NULTextFieldStyle())
                .focused($isFilenameFocused)
                .onSubmit(confirmRename)

            HStack(spacing: AppTheme.gridUnit * 2) {
                Spacer()

                Button("Cancel", action: cancelAction)
                    .buttonStyle(NULButtonStyle(kind: .neutral, accentColor: accentColor))
                    .keyboardShortcut(.cancelAction)

                Button("Rename", action: confirmRename)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(NULButtonStyle(kind: .primary, accentColor: accentColor))
                    .disabled(!isFilenameValid)
            }
        }
        .padding(AppTheme.gridUnit * 5)
        .frame(width: 320)
        .task {
            isFilenameFocused = true
        }
    }

    private var isFilenameValid: Bool {
        let candidate = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        return !candidate.isEmpty
            && candidate != "."
            && candidate != ".."
            && !candidate.contains("/")
            && !candidate.contains(":")
    }

    private func confirmRename() {
        guard isFilenameValid else { return }
        _ = renameAction(filename)
    }
}
