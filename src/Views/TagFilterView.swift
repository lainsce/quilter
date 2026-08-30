import SwiftUI

/// A wrapping list of tag chips that filters the sidebar's file list. Tapping a
/// chip toggles the active tag filter on `AppState`.
struct TagFilterView: View {
    @Bindable var appState: AppState

    private let columns = [
        GridItem(.adaptive(minimum: 56, maximum: 200), spacing: AppTheme.gridUnit * 2, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppTheme.gridUnit * 2) {
            ForEach(appState.allTags, id: \.self) { tag in
                TagChip(
                    tag: tag,
                    isSelected: appState.selectedTag?.lowercased() == tag.lowercased(),
                    action: { appState.toggleTagFilter(tag) }
                )
            }
        }
    }
}
