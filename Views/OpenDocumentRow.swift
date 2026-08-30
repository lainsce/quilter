import SwiftUI

struct OpenDocumentRow: View {
    @Bindable var document: DocumentItem
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let selectAction: () -> Void
    let closeAction: () -> Void
    let saveAndCloseAction: () -> Void

    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingCloseConfirmation = false
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: AppTheme.gridUnit * 3) {
            Button(action: selectAction) {
                HStack(alignment: .center, spacing: AppTheme.gridUnit * 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: AppTheme.gridUnit) {
                            if isSelected && differentiateWithoutColor {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }

                            Text(document.filename)
                                .font(AppTheme.body)
                                .lineLimit(1)

                            if document.isDirty {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Unsaved changes")
                            }
                        }

                        Text(document.summary ?? "")
                            .font(AppTheme.micro)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(QuilterSidebarRowButtonStyle())
            .accessibilityLabel(document.filename)
            .accessibilityValue(Text(selectionAccessibilityValue))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button("Close \(document.filename)", systemImage: "xmark") {
                if document.isDirty {
                    isShowingCloseConfirmation = true
                } else {
                    closeAction()
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .frame(width: 38, height: 38)
            // The close affordance stays on the content layer. Its 38-point
            // frame preserves the native hit target without another capsule
            // competing with the document row.
            .contentShape(.rect)
            .help("Close \(document.filename)")
            .confirmationDialog(
                "Save changes to \(document.filename)?",
                isPresented: $isShowingCloseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save and Close", action: saveAndCloseAction)
                Button("Discard Changes", role: .destructive, action: closeAction)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your changes will be lost if you close this document without saving.")
            }
        }
        .padding(.horizontal, AppTheme.gridGutter)
        .frame(minHeight: AppTheme.rowHeight)
        .background(rowBackground, in: rowShape)
        .overlay {
            if isSelected && isHovering {
                rowShape
                    .strokeBorder(
                        accentColor.opacity(AppTheme.sidebarSelectedBorderOpacity),
                        lineWidth: 1
                    )
            }
        }
        .contentShape(.rect)
        .onHover { isHovering = $0 }
        .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: isHovering)
    }

    private var rowShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? AppTheme.documentListCornerRadius : 0,
            bottomLeadingRadius: isLast ? AppTheme.documentListCornerRadius : 0,
            bottomTrailingRadius: isLast ? AppTheme.documentListCornerRadius : 0,
            topTrailingRadius: isFirst ? AppTheme.documentListCornerRadius : 0
        )
    }

    private var rowBackground: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(accentColor.opacity(AppTheme.sidebarSelectedFillOpacity))
        }

        if isHovering {
            return AnyShapeStyle(AppTheme.sidebarHoverFill(for: colorScheme))
        }

        return AnyShapeStyle(.clear)
    }

    private var selectionAccessibilityValue: LocalizedStringResource {
        isSelected ? "Selected" : "Not selected"
    }
}
