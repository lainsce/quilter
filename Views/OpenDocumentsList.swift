import SwiftUI

struct OpenDocumentsList: View {
    @Bindable var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let documents = appState.filteredDocuments
        LazyVStack(spacing: 0) {
            ForEach(documents) { document in
                OpenDocumentRow(
                    document: document,
                    isSelected: appState.selectedDocumentID == document.id,
                    isFirst: document.id == documents.first?.id,
                    isLast: document.id == documents.last?.id,
                    selectAction: { appState.select(document) },
                    closeAction: { appState.close(document) },
                    saveAndCloseAction: { appState.saveAndClose(document) }
                )

                if document.id != documents.last?.id {
                    Rectangle()
                        .fill(AppTheme.sidebarDivider(for: colorScheme))
                        .frame(height: 1)
                }
            }
        }
    }
}
