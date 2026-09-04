import AppKit
import SwiftUI

struct EditorSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        NULSettingsPage {
            NULSettingsSection("Document") {
                NULSettingsItem {
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
                }

                NULSettingsItem {
                    NULFormRow("Column Width") {
                        NULSegmentedPicker(
                            selection: $preferences.columnCharacterCount,
                            options: [64, 72, 80]
                        ) { value in
                            Text("\(value)")
                                .font(AppTheme.technicalFont(role: .body))
                        }
                    }
                }

                NULSettingsItem {
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
                }

                NULSettingsItem {
                    NULFormRow("Autosave") {
                        Toggle("", isOn: $preferences.autosave)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Autosave")
                    }
                }
            }

            NULSettingsSection("Interface") {
                NULSettingsItem {
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
                }

                NULSettingsItem {
                    NULFormRow("Focus Scope") {
                        NULSegmentedPicker(
                            selection: $preferences.focusScope,
                            options: FocusScope.allCases
                        ) { scope in
                            Text(scope.title)
                        }
                    }
                }

                NULSettingsItem {
                    NULFormRow("Typewriter Scrolling") {
                        Toggle("", isOn: $preferences.typewriterScrolling)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Typewriter Scrolling")
                    }
                }

                NULSettingsItem {
                    NULFormRow("Document Tracker") {
                        Toggle("", isOn: $preferences.showsDocumentTracker)
                            .labelsHidden()
                            .toggleStyle(NULToggleStyle())
                            .accessibilityLabel("Document Tracker")
                    }
                }
            }

            NULSettingsSection(
                "Speech Parts",
                footer: "Only available in English, Spanish, Portuguese, Arabic, Mandarin Chinese, Korean, Japanese, and French."
            ) {
                NULSettingsItem {
                    NULFormRow("Nouns") { Toggle("", isOn: $preferences.highlightsNouns).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Nouns") }
                }
                NULSettingsItem {
                    NULFormRow("Verbs") { Toggle("", isOn: $preferences.highlightsVerbs).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Verbs") }
                }
                NULSettingsItem {
                    NULFormRow("Adjectives") { Toggle("", isOn: $preferences.highlightsAdjectives).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Adjectives") }
                }
                NULSettingsItem {
                    NULFormRow("Adverbs") { Toggle("", isOn: $preferences.highlightsAdverbs).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Adverbs") }
                }
                NULSettingsItem {
                    NULFormRow("Conjunctions") { Toggle("", isOn: $preferences.highlightsConjunctions).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Conjunctions") }
                }
            }

            NULSettingsSection(
                "Writing Focus",
                footer: "Highlights fillers, clichés, and redundancies to be removed."
            ) {
                NULSettingsItem {
                    NULFormRow("Cliches") { Toggle("", isOn: $preferences.checksCliches).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Cliches") }
                }
                NULSettingsItem {
                    NULFormRow("Redundancies") { Toggle("", isOn: $preferences.checksRedundancies).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Redundancies") }
                }
                NULSettingsItem {
                    NULFormRow("Fillers") { Toggle("", isOn: $preferences.checksFillers).labelsHidden().toggleStyle(NULToggleStyle()).accessibilityLabel("Fillers") }
                }
            }
        }
    }
}
