import SwiftUI

struct ActiveDocumentTitle: View {
    @Bindable var appState: AppState
    @State private var isShowingRenamePopover = false

    var body: some View {
        Button(action: showRenamePopover) {
            VStack(alignment: .leading, spacing: 0) {
                Text(appState.selectedDocument?.filename ?? "Quilter")
                    .font(AppTheme.body)
                    .lineLimit(1)

                if let document = appState.selectedDocument {
                    Text(document.directoryDisplayName)
                        .font(AppTheme.technicalFont(role: .micro))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Markdown Editor")
                        .font(AppTheme.micro)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: AppTheme.toolbarControlSize, alignment: .leading)
        .contentShape(.rect(cornerRadius: AppTheme.industrialCornerRadius))
        .disabled(appState.selectedDocument == nil)
        .help(Text(helpText))
        .accessibilityLabel("Active document")
        .accessibilityValue(accessibilityValue)
        .popover(isPresented: $isShowingRenamePopover, arrowEdge: .bottom) {
            Group {
                if let document = appState.selectedDocument {
                    RenameDocumentPopover(
                        currentFilename: document.filename,
                        renameAction: renameDocument,
                        cancelAction: dismissRenamePopover
                    )
                }
            }
            .presentationBackground(AppTheme.industrialSurface)
        }
        .onChange(of: appState.selectedDocumentID) { _, _ in
            dismissRenamePopover()
        }
    }

    private func showRenamePopover() {
        guard appState.selectedDocument != nil else { return }
        isShowingRenamePopover = true
    }

    private func renameDocument(to filename: String) -> Bool {
        let didRename = appState.renameSelectedDocument(to: filename)
        if didRename {
            dismissRenamePopover()
        }
        return didRename
    }

    private func dismissRenamePopover() {
        isShowingRenamePopover = false
    }

    private var helpText: LocalizedStringResource {
        appState.selectedDocument == nil ? "No Document Selected" : "Rename Document"
    }

    private var accessibilityValue: Text {
        if let filename = appState.selectedDocument?.filename {
            Text(verbatim: filename)
        } else {
            Text("No document selected")
        }
    }
}
