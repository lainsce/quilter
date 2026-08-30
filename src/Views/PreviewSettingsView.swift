import SwiftUI

struct PreviewSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        ScrollView(.vertical) {
            Form {
                Section("General") {
                    NULFormRow("Preview Font Type") {
                        NULMenuPicker(
                            "Preview Font Type",
                            selection: $preferences.previewFont,
                            options: PreviewFontType.allCases,
                            showsTitle: false
                        ) { font in
                            Text(font.title)
                        }
                    }

                    NULFormRow(
                        "Header Centering",
                        description: "This affects #, ##, and ### headers."
                    ) {
                        Toggle("", isOn: $preferences.centersPreviewHeaders)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Header Centering")
                    }
                }

                Section("Extensions") {
                    NULFormRow(
                        "Code Highlight",
                        description: "Code blocks receive syntax coloring."
                    ) {
                        Toggle("", isOn: $preferences.highlightsPreviewCode)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Code Highlight")
                    }

                    NULFormRow(
                        "LaTeX Math",
                        description: "LaTeX math blocks are rendered in the preview."
                    ) {
                        Toggle("", isOn: $preferences.rendersLaTeXMath)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("LaTeX Math")
                    }

                    NULFormRow(
                        "Mermaid.js Graph",
                        description: "Mermaid code blocks become graphs in the preview."
                    ) {
                        Toggle("", isOn: $preferences.rendersMermaidGraphs)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Mermaid.js Graph")
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .background(AppTheme.industrialSurface, in: RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous))
        }
        .scrollIndicators(.automatic)
        .background(AppTheme.industrialSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .defaultScrollAnchor(.top)
        .padding(AppTheme.gridSectionGap)
    }
}
