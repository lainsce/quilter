import SwiftUI

enum QuilterWindowID {
    static let about = "about"
    static let privacyPolicy = "privacy-policy"
}

@main
struct QuilterApp: App {
    @NSApplicationDelegateAdaptor(QuilterApplicationDelegate.self)
    private var applicationDelegate
    @State private var preferences: AppPreferences
    @State private var appState: AppState
    @State private var chromeState: WindowChromeState

    init() {
        let preferences = AppPreferences()
        _preferences = State(initialValue: preferences)
        _appState = State(initialValue: AppState(preferences: preferences))
        _chromeState = State(initialValue: WindowChromeState())
    }

    var body: some Scene {
        WindowGroup {
            AppWindowView(appState: appState, preferences: preferences)
                .font(AppTheme.body)
                .nulWindowActivityAppearance()
                .frame(minWidth: 900, minHeight: 600)
                .background(
                    WindowConfigurationView(
                        preferences: preferences,
                        isFocusMode: appState.isFocusMode,
                        isSidebarVisible: appState.isSidebarVisible,
                        isToolbarPopoverPresented: appState.isToolbarPopoverPresented,
                        chromeState: chromeState
                    )
                )
                .environment(chromeState)
                .tint(AppTheme.accentColor)
                .environment(\.appAccentColor, AppTheme.accentColor)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .onAppear {
                    applicationDelegate.appState = appState
                }
        }
        .defaultSize(width: 1_024, height: 800)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            QuilterCommands(appState: appState)
        }

        Window("About Quilter", id: QuilterWindowID.about) {
            QuilterAboutView()
                .font(AppTheme.body)
                .nulWindowActivityAppearance()
                .tint(AppTheme.accentColor)
                .environment(\.appAccentColor, AppTheme.accentColor)
        }
        .defaultSize(width: 440, height: 520)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        Window("Privacy Policy", id: QuilterWindowID.privacyPolicy) {
            PrivacyPolicyView()
                .font(AppTheme.body)
                .nulWindowActivityAppearance()
                .tint(AppTheme.accentColor)
                .environment(\.appAccentColor, AppTheme.accentColor)
        }
        .defaultSize(width: 640, height: 560)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        Settings {
            SettingsView(appState: appState, preferences: preferences)
                .font(AppTheme.body)
                .nulWindowActivityAppearance()
                .tint(AppTheme.accentColor)
                .environment(\.appAccentColor, AppTheme.accentColor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
