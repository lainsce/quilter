import AppKit
import SwiftUI

struct EditorSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        ScrollView(.vertical) {
            Form {
                Section("Document") {
                    NULFormRow("Font Type") {
                        NULMenuPicker(
                            "Font Type",
                            selection: $preferences.editorFont,
                            options: EditorFontType.allCases,
                            showsTitle: false
                        ) { font in
                            Text(font.title)
                        }
                    }

                    NULFormRow("Column Width") {
                        NULSegmentedPicker(
                            selection: $preferences.columnCharacterCount,
                            options: [64, 72, 80]
                        ) { value in
                            Text("\(value)")
                        }
                    }

                    NULFormRow("Highlight Color") {
                        NULMenuPicker(
                            "Highlight Color",
                            selection: $preferences.highlightColor,
                            options: MarkdownHighlightColor.allCases,
                            showsTitle: false
                        ) { color in
                            Label {
                                Text(color.title)
                            } icon: {
                                Circle().fill(Color(nsColor: color.nsColor)).frame(width: 12, height: 12)
                            }
                        }
                    }

                    NULFormRow("Autosave") {
                        Toggle("", isOn: $preferences.autosave)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Autosave")
                    }
                }

                Section("Interface") {
                    NULFormRow("Normal Mode Toolbar") {
                        NULMenuPicker(
                            "Normal Mode Toolbar",
                            selection: $preferences.toolbarVisibility,
                            options: ToolbarVisibilityMode.allCases,
                            showsTitle: false
                        ) { mode in
                            Text(mode.title)
                        }
                    }

                    NULFormRow("Focus Scope") {
                        NULSegmentedPicker(
                            selection: $preferences.focusScope,
                            options: FocusScope.allCases
                        ) { scope in
                            Text(scope.title)
                        }
                    }

                    NULFormRow("Typewriter Scrolling") {
                        Toggle("", isOn: $preferences.typewriterScrolling)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Typewriter Scrolling")
                    }

                    NULFormRow("Document Tracker") {
                        Toggle("", isOn: $preferences.showsDocumentTracker)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Document Tracker")
                    }
                }

                Section {
                    NULFormRow("Nouns") { Toggle("", isOn: $preferences.highlightsNouns).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Nouns") }
                    NULFormRow("Verbs") { Toggle("", isOn: $preferences.highlightsVerbs).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Verbs") }
                    NULFormRow("Adjectives") { Toggle("", isOn: $preferences.highlightsAdjectives).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Adjectives") }
                    NULFormRow("Adverbs") { Toggle("", isOn: $preferences.highlightsAdverbs).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Adverbs") }
                    NULFormRow("Conjunctions") { Toggle("", isOn: $preferences.highlightsConjunctions).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Conjunctions") }
                } header: {
                    Text("Speech Parts")
                } footer: {
                    Text("Only available in English, Spanish, Portuguese, Arabic, Mandarin Chinese, Korean, Japanese, and French.")
                }

                Section {
                    NULFormRow("Cliches") { Toggle("", isOn: $preferences.checksCliches).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Cliches") }
                    NULFormRow("Redundancies") { Toggle("", isOn: $preferences.checksRedundancies).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Redundancies") }
                    NULFormRow("Fillers") { Toggle("", isOn: $preferences.checksFillers).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Fillers") }
                } header: {
                    Text("Writing Focus")
                } footer: {
                    Text("Highlights fillers, clichés, and redundancies to be removed.")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .background(AppTheme.industrialSurface, in: RoundedRectangle(cornerRadius: AppTheme.industrialLargeCornerRadius, style: .continuous))
            .padding(AppTheme.gridSectionGap)
        }
        .scrollIndicators(.automatic)
        .background(AppTheme.industrialSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .defaultScrollAnchor(.top)
    }
}
