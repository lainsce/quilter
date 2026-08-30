import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class WindowChromeState {
    var isVisible = true
}

struct WindowConfigurationView: NSViewRepresentable {
    @Bindable var preferences: AppPreferences
    let isFocusMode: Bool
    let isSidebarVisible: Bool
    let isToolbarPopoverPresented: Bool
    let chromeState: WindowChromeState

    func makeNSView(context: Context) -> WindowConfigurationNSView {
        WindowConfigurationNSView()
    }

    func updateNSView(_ nsView: WindowConfigurationNSView, context: Context) {
        nsView.updateBackground()
        nsView.updateToolbarVisibility(
            preferences.toolbarVisibility,
            isFocusMode: isFocusMode,
            isToolbarPopoverPresented: isToolbarPopoverPresented,
            chromeState: chromeState
        )
        nsView.updateSidebarBoundary(
            isVisible: isSidebarVisible && !isFocusMode,
            sidebarWidth: AppWindowView.sidebarIdealWidth
        )
    }
}
