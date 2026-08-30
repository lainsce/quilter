import AppKit
import SwiftUI

struct EditorActionsMenu: View {
    @Bindable var appState: AppState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.appAccentColor) private var accentColor
    @State private var isPresented = false
    @State private var showsCheatsheet = false

    var body: some View {
        Button("Editor Actions", systemImage: "ellipsis") {
            isPresented.toggle()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(NULToolbarButtonStyle())
        .help("Document and Editor Actions")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    layoutButton(.editorOnly, icon: "pencil", title: "Editor")
                    layoutButton(.split, icon: "rectangle.split.2x1", title: "Split")
                    layoutButton(.previewOnly, icon: "doc.richtext", title: "Preview")
                }
                .disabled(appState.selectedDocument == nil || appState.isFocusMode)

                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: AppTheme.delimiterThickness)
                    .padding(.horizontal, AppTheme.gridSmallGap)

                menuRow("Cheatsheet…", icon: "text.book.closed") {
                    isPresented = false
                    showsCheatsheet = true
                }

                menuRow("Preferences…", icon: "gearshape") {
                    isPresented = false
                    openSettings()
                }
            }
            .padding(AppTheme.gridUnit * 2)
            // A popover has no useful intrinsic width when its three layout
            // buttons all request `maxWidth: .infinity`. Give the anchor a
            // finite geometry so SwiftUI does not negotiate an ambiguous
            // toolbar/popover layout while it is being presented.
            .frame(width: 340)
            .background(
                AppTheme.industrialSurface,
                in: .rect(cornerRadius: AppTheme.industrialLargeCornerRadius)
            )
            .presentationBackground(AppTheme.industrialSurface)
        }
        .sheet(isPresented: $showsCheatsheet) {
            CheatsheetView()
                .tint(accentColor)
        }
        .onChange(of: isPresented) { _, isPresented in
            appState.isToolbarPopoverPresented = isPresented
        }
        .onDisappear {
            appState.isToolbarPopoverPresented = false
        }
    }

    @ViewBuilder
    private func menuRow(
        _ title: LocalizedStringResource,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.gridUnit * 2) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(AppTheme.body)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, AppTheme.gridUnit)
            .padding(.horizontal, AppTheme.gridUnit * 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func layoutButton(
        _ layout: EditorLayout,
        icon: String,
        title: LocalizedStringResource
    ) -> some View {
        let isSelected = appState.editorLayout == layout
        Button {
            appState.setEditorLayout(layout)
            isPresented = false
        } label: {
            VStack(spacing: AppTheme.gridUnit * 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundStyle(.primary)
                    .frame(width: AppTheme.gridUnit * 10, height: AppTheme.gridUnit * 6)
                Text(title)
                    .font(AppTheme.micro)
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.gridUnit * 2)
            .padding(.horizontal, AppTheme.gridUnit * 3)
            .background(
                isSelected ? accentColor.opacity(0.12) : .clear,
                in: .rect(cornerRadius: AppTheme.industrialSmallCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.industrialSmallCornerRadius)
                    .strokeBorder(accentColor.opacity(0.70), lineWidth: 1)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }

}
