import SwiftUI

struct FocusModeExitButton: View {
    let action: () -> Void

    var body: some View {
        Button(
            "Exit Focus Mode",
            systemImage: "arrow.down.right.and.arrow.up.left",
            action: action
        )
        .labelStyle(.iconOnly)
        .buttonStyle(NULToolbarButtonStyle())
        .help("Exit Focus Mode (Esc)")
        .keyboardShortcut(.escape, modifiers: [])
        .accessibilityLabel("Exit Focus Mode")
    }
}
