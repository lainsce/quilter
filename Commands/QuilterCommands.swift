import SwiftUI

struct QuilterCommands: Commands {
    @AppStorage(EditorStatusMetric.selectionDefaultsKey)
    private var selectedMetricRawValue = EditorStatusMetric.sentences.rawValue
    @Environment(\.openWindow) private var openWindow

    let appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Quilter", systemImage: "info.circle") {
                openWindow(id: QuilterWindowID.about)
            }
        }

        CommandGroup(after: .help) {
            Button("Privacy Policy", systemImage: "hand.raised") {
                openWindow(id: QuilterWindowID.privacyPolicy)
            }
        }

        CommandGroup(replacing: .newItem) {
            Button(
                "New Document",
                systemImage: "doc.badge.plus",
                action: appState.newDocument
            )
                .keyboardShortcut("n", modifiers: .command)

            Button(
                "Open…",
                systemImage: "folder",
                action: appState.showOpenPanel
            )
                .keyboardShortcut("o", modifiers: .command)

            Menu("Open Recent", systemImage: "clock.arrow.circlepath") {
                if appState.recentFileURLs.isEmpty {
                    Button("No Recent Documents") { }
                        .disabled(true)
                } else {
                    ForEach(appState.recentFileURLs, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            appState.open(urls: [url])
                        }
                    }
                }

                Divider()

                Button(
                    "Clear Menu",
                    systemImage: "trash",
                    action: appState.clearRecentFiles
                )
                .disabled(appState.recentFileURLs.isEmpty)
            }
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save", systemImage: "arrow.down.to.line", action: appState.saveSelected)
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appState.selectedDocument == nil)

            Button("Save As…", systemImage: "doc.badge.arrow.up", action: appState.saveSelectedAs)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(appState.selectedDocument == nil)
        }

        CommandGroup(after: .saveItem) {
            Button(
                "Close Current Document",
                systemImage: "xmark",
                action: appState.closeSelectedPromptingIfNeeded
            )
                .keyboardShortcut("w", modifiers: [.command, .option])
                .disabled(appState.selectedDocument == nil)
        }

        CommandGroup(replacing: .toolbar) {
            Picker(
                "View",
                selection: Binding(
                    get: { appState.editorLayout },
                    set: { appState.setEditorLayout($0) }
                )
            ) {
                Label("Editor Only", systemImage: "pencil")
                    .tag(EditorLayout.editorOnly)
                Label("Editor + Preview", systemImage: "rectangle.split.2x1")
                    .tag(EditorLayout.split)
                Label("Preview Only", systemImage: "doc.richtext")
                    .tag(EditorLayout.previewOnly)
            }
            .pickerStyle(.inline)
            .disabled(appState.selectedDocument == nil || appState.isFocusMode)

            Divider()

            Button(
                appState.isFocusMode ? "Exit Focus Mode" : "Enter Focus Mode",
                systemImage: "viewfinder",
                action: appState.toggleFocusMode
            )
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(appState.selectedDocument == nil && !appState.isFocusMode)

            Divider()

            Button(
                "Next Document",
                systemImage: "arrow.right",
                action: appState.selectNextDocument
            )
            .keyboardShortcut(.tab, modifiers: [.control])
            .disabled(!appState.canCycleDocuments)

            Button(
                "Previous Document",
                systemImage: "arrow.left",
                action: appState.selectPreviousDocument
            )
            .keyboardShortcut(.tab, modifiers: [.control, .shift])
            .disabled(!appState.canCycleDocuments)

            Divider()

            Menu("Editor Statistic", systemImage: "chart.bar") {
                Picker("Editor Statistic", selection: $selectedMetricRawValue) {
                    ForEach(EditorStatusMetric.allCases) { metric in
                        Label(metric.title, systemImage: metric.systemImage)
                            .tag(metric.rawValue)
                    }
                }
            }
        }
    }
}
