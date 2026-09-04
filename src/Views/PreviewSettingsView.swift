import SwiftUI

struct PreviewSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        NULSettingsPage {
            NULSettingsSection("General") {
                NULSettingsItem {
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
                }

                NULSettingsItem {
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
            }

            NULSettingsSection("Extensions") {
                NULSettingsItem {
                    NULFormRow(
                        "Code Highlight",
                        description: "Code blocks receive syntax coloring."
                    ) {
                        Toggle("", isOn: $preferences.highlightsPreviewCode)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Code Highlight")
                    }
                }

                NULSettingsItem {
                    NULFormRow(
                        "LaTeX Math",
                        description: "LaTeX math blocks are rendered in the preview."
                    ) {
                        Toggle("", isOn: $preferences.rendersLaTeXMath)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("LaTeX Math")
                    }
                }

                NULSettingsItem {
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
        }
    }
}
