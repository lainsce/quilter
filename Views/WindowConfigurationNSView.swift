import AppKit
import QuartzCore

final class WindowConfigurationNSView: NSView {
    private var toolbarVisibility = ToolbarVisibilityMode.hover
    private var isFocusMode = false
    private var isToolbarPopoverPresented = false
    private var isWindowChromeVisible = true
    private var hasAppliedChromeState = false
    private var mouseMonitor: Any?
    private var accessibilityOptionsObserver: NSObjectProtocol?
    private weak var chromeState: WindowChromeState?
    private weak var configuredWindow: NSWindow?
    private var previousAcceptsMouseMovedEvents: Bool?
    private var pendingSidebarBoundaryVisible = false
    private var pendingSidebarWidth: CGFloat = 300
    private var sidebarBoundaryOverlay: SidebarBoundaryOverlayView?

    // A small hysteresis band keeps the chrome from flickering when the
    // pointer pauses right at the reveal boundary.
    private let toolbarShowHoverHeight: CGFloat = 72
    private let toolbarHideHoverHeight: CGFloat = 88

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            stopFocusTracking()
            stopAccessibilityOptionsTracking()
            sidebarBoundaryOverlay?.removeFromSuperview()
            sidebarBoundaryOverlay = nil
            configuredWindow = nil
            return
        }

        if configuredWindow !== window {
            stopFocusTracking()
            sidebarBoundaryOverlay?.removeFromSuperview()
            sidebarBoundaryOverlay = nil
            configuredWindow = window
            hasAppliedChromeState = false
            isWindowChromeVisible = true
            startAccessibilityOptionsTracking()
        }

        window.minSize = NSSize(width: 900, height: 600)
        window.setFrameAutosaveName("Quilter.MainWindow")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        applyBackground(to: window)
        applyToolbarVisibility(to: window)
        applySidebarBoundary(to: window)
    }

    func updateBackground() {
        guard let window else { return }
        applyBackground(to: window)
    }

    func updateToolbarVisibility(
        _ toolbarVisibility: ToolbarVisibilityMode,
        isFocusMode: Bool,
        isToolbarPopoverPresented: Bool,
        chromeState: WindowChromeState
    ) {
        self.toolbarVisibility = toolbarVisibility
        self.isFocusMode = isFocusMode
        self.isToolbarPopoverPresented = isToolbarPopoverPresented
        self.chromeState = chromeState
        guard let window else { return }
        applyToolbarVisibility(to: window)
    }

    func updateSidebarBoundary(isVisible: Bool, sidebarWidth: CGFloat) {
        pendingSidebarBoundaryVisible = isVisible
        pendingSidebarWidth = sidebarWidth
        guard let window else { return }
        applySidebarBoundary(to: window)
    }

    isolated deinit {
        stopFocusTracking()
        stopAccessibilityOptionsTracking()
    }

    private var accessibilityNavigationIsEnabled: Bool {
        NSApp.isFullKeyboardAccessEnabled
            || NSWorkspace.shared.isVoiceOverEnabled
            || NSWorkspace.shared.isSwitchControlEnabled
    }

    private func applyBackground(to window: NSWindow) {
        let lightWorkspace = NSColor(srgbRed: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1)
        let darkWorkspace = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

        window.backgroundColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? darkWorkspace
                : lightWorkspace
        }
    }

    private func applySidebarBoundary(to window: NSWindow) {
        guard let contentView = window.contentView else { return }
        let hostView = contentView.superview ?? contentView
        let hostBounds = hostView.bounds

        guard pendingSidebarBoundaryVisible else {
            sidebarBoundaryOverlay?.isHidden = true
            return
        }

        let overlay: SidebarBoundaryOverlayView
        if let existingOverlay = sidebarBoundaryOverlay {
            overlay = existingOverlay
            if overlay.superview !== hostView {
                overlay.removeFromSuperview()
                hostView.addSubview(overlay, positioned: .above, relativeTo: nil)
            }
        } else {
            overlay = SidebarBoundaryOverlayView()
            sidebarBoundaryOverlay = overlay
            hostView.addSubview(overlay, positioned: .above, relativeTo: nil)
        }

        overlay.isHidden = false
        overlay.autoresizingMask = [.height]
        overlay.layer?.zPosition = 1_000
        overlay.frame = NSRect(
            x: hostBounds.minX + max(0, pendingSidebarWidth - SidebarBoundaryOverlayView.overlayWidth),
            y: hostBounds.minY,
            width: SidebarBoundaryOverlayView.overlayWidth,
            height: hostBounds.height
        )
        overlay.needsDisplay = true
    }

    private func applyToolbarVisibility(to window: NSWindow) {
        if isToolbarPopoverPresented {
            stopFocusTracking()
            setWindowChromeVisible(true, in: window)
            return
        }

        let mode = isFocusMode ? ToolbarVisibilityMode.hover : toolbarVisibility

        switch mode {
        case .alwaysHidden:
            stopFocusTracking()
            setWindowChromeVisible(false, in: window)
        case .hover:
            // Keep the monitor alive while accessibility navigation is
            // enabled so switching that setting back off takes effect on the
            // next native mouse or keyboard event without requiring a relaunch.
            startFocusTracking(on: window)
            setWindowChromeVisible(
                accessibilityNavigationIsEnabled || pointerIsInHoverRegion(for: window),
                in: window
            )
        case .alwaysShown:
            stopFocusTracking()
            setWindowChromeVisible(true, in: window)
        }
    }

    private func startAccessibilityOptionsTracking() {
        guard accessibilityOptionsObserver == nil else { return }

        accessibilityOptionsObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let window = self.configuredWindow else { return }
                self.applyToolbarVisibility(to: window)
            }
        }
    }

    private func stopAccessibilityOptionsTracking() {
        guard let accessibilityOptionsObserver else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(accessibilityOptionsObserver)
        self.accessibilityOptionsObserver = nil
    }

    private func startFocusTracking(on window: NSWindow) {
        guard mouseMonitor == nil else { return }

        previousAcceptsMouseMovedEvents = window.acceptsMouseMovedEvents
        window.acceptsMouseMovedEvents = true

        mouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [
                .mouseMoved,
                .leftMouseDown,
                .rightMouseDown,
                .otherMouseDown,
                .keyDown
            ]
        ) { [weak self, weak window] event in
            guard let self, let window else { return event }

            if self.accessibilityNavigationIsEnabled {
                self.setWindowChromeVisible(true, in: window)
            } else if event.type == .keyDown && self.isKeyboardNavigationKey(event) {
                // Keyboard navigation must have a visible destination even
                // when the pointer is outside the hover zone. Returning the
                // event unchanged keeps the native key loop intact.
                self.setWindowChromeVisible(true, in: window)
            } else {
                self.setWindowChromeVisible(
                    self.pointerIsInHoverRegion(for: window),
                    in: window
                )
            }
            return event
        }
    }

    private func isKeyboardNavigationKey(_ event: NSEvent) -> Bool {
        // Tab moves through toolbar controls. Arrow keys remain ordinary
        // caret navigation in the editor and should not reveal the chrome.
        event.keyCode == 48
    }

    private func stopFocusTracking() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }

        if let window = configuredWindow,
           let previousAcceptsMouseMovedEvents {
            window.acceptsMouseMovedEvents = previousAcceptsMouseMovedEvents
        }
        previousAcceptsMouseMovedEvents = nil
    }

    private func pointerIsInHoverRegion(for window: NSWindow) -> Bool {
        let pointer = NSEvent.mouseLocation
        let frame = window.frame
        let hoverHeight = isWindowChromeVisible
            ? toolbarHideHoverHeight
            : toolbarShowHoverHeight
        return frame.contains(pointer) && pointer.y >= frame.maxY - hoverHeight
    }

    private func setWindowChromeVisible(_ visible: Bool, in window: NSWindow) {
        let stateChanged = isWindowChromeVisible != visible
        isWindowChromeVisible = visible
        if chromeState?.isVisible != visible {
            chromeState?.isVisible = visible
        }
        // Keep the toolbar in the title-bar layout at all times. Hiding the
        // NSToolbar itself causes the editor to jump as the pointer crosses the
        // reveal zone; fading its controls keeps the document geometry stable.
        window.toolbar?.isVisible = true

        let toolbarItems = window.toolbar?.items ?? []
        let toolbarViews = toolbarItems.compactMap(\.view)
        let trafficLightButtons = [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton
        ]
        .compactMap { window.standardWindowButton($0) }
        let chromeViews: [NSView] = toolbarViews + trafficLightButtons.map { $0 as NSView }
        let alpha: CGFloat = visible ? 1 : 0

        toolbarItems.forEach {
            $0.isEnabled = visible
            $0.isHidden = !visible
        }
        trafficLightButtons.forEach { $0.isEnabled = visible }

        if visible {
            chromeViews.forEach { $0.isHidden = false }
        }

        let shouldAnimate = stateChanged
            && hasAppliedChromeState
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        hasAppliedChromeState = true

        guard shouldAnimate else {
            chromeViews.forEach { $0.alphaValue = alpha }
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = visible
                ? AppTheme.toolbarRevealDuration
                : AppTheme.toolbarHideDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            chromeViews.forEach { $0.animator().alphaValue = alpha }
        }
    }
}

private final class SidebarBoundaryOverlayView: NSView {
    // The boundary is a single background-colored strip. Keeping the overlay
    // narrow prevents it from becoming a second pane or adding a decorative
    // shadow to the content surface.
    static let overlayWidth: CGFloat = 2
    static let lineOffset: CGFloat = overlayWidth - 1

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.height]
        wantsLayer = true
        layer?.isOpaque = false
        layer?.masksToBounds = true
        layer?.zPosition = 1_000
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.height]
        wantsLayer = true
        layer?.isOpaque = false
        layer?.masksToBounds = true
        layer?.zPosition = 1_000
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        // Keep the pane boundary to one quiet 12% black/white rule. The
        // sidebar surface is opaque, so no shadow or translucent strip is
        // needed to separate it from the editor.
        AppTheme.sidebarDividerColor(for: effectiveAppearance).setFill()
        NSBezierPath(
            rect: NSRect(
                x: Self.lineOffset,
                y: bounds.minY,
                width: 1,
                height: bounds.height
            )
        ).fill()
    }
}
