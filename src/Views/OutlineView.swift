import SwiftUI

struct OutlineView: View {
    var document: DocumentItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarSectionHeader(title: "Outline")

            if let document, !document.headings.isEmpty {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(document.headings) { heading in
                        OutlineRow(heading: heading) {
                            document.requestScroll(to: heading)
                        }
                    }
                }
            } else {
                Text(emptyStateMessage(hasDocument: document != nil))
                    .font(AppTheme.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, AppTheme.gridUnit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private func emptyStateMessage(hasDocument: Bool) -> LocalizedStringResource {
        hasDocument ? "No headings" : "Select a document"
    }
}
