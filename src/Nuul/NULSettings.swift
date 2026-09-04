import SwiftUI

/// A settings window surface with Nuul's workspace layer and a visible
/// `ViewTitle`. Settings content supplies its own tab bar and page below the
/// title so the same shell can be reused by preference windows and sheets.
struct NULSettingsWindow<Content: View>: View {
    private let title: LocalizedStringKey
    private let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        _ title: LocalizedStringKey = "Settings",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(AppTheme.viewTitle)
                .foregroundStyle(.primary)
                .padding(.horizontal, AppTheme.settingsTitleInset)
                .padding(.top, AppTheme.settingsTitleInset)
                .padding(.bottom, AppTheme.settingsTitleBottomSpacing)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.workspaceBackground(for: colorScheme))
        .nulWindowActivityAppearance()
    }
}

/// Scrollable settings page. Its rows meet the window edges but not the
/// rounded corners, so it stays on the ordinary eight-point module rhythm.
struct NULSettingsPage<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: AppTheme.settingsSectionSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.settingsWindowInset)
            .padding(.top, AppTheme.settingsWindowInset)
            .padding(.bottom, AppTheme.settingsWindowInset)
        }
        .scrollIndicators(.automatic)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .defaultScrollAnchor(.top)
    }
}

/// A labelled group of independent settings items. The section itself stays
/// on the workspace layer; only its rows receive an item surface.
struct NULSettingsSection<Content: View>: View {
    private let title: LocalizedStringKey?
    private let footer: LocalizedStringKey?
    private let content: Content

    init(
        _ title: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.settingsItemSpacing) {
            if let title {
                Text(title)
                    .font(AppTheme.caption)
                    .textCase(.uppercase)
                    .kerning(0.4)
                    .foregroundStyle(.secondary)
            }

            content

            if let footer {
                Text(footer)
                    .font(AppTheme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One opaque setting surface. Keeping rows separate from their section gives
/// Nuul the visual grouping of native settings without importing Form chrome.
struct NULSettingsItem<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, AppTheme.settingsItemPadding)
            .padding(.vertical, AppTheme.settingsItemPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.industrialSurface,
                in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
            )
    }
}

/// Chrome-1.0-inspired tabs: the selected tab is a trapezoid that joins the
/// workspace below, while unselected tabs expose only a quiet baseline.
struct NULTabBar<Selection: Hashable, ItemLabel: View>: View {
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(
        selection: Binding<Selection>,
        options: [Selection],
        @ViewBuilder label: @escaping (Selection) -> ItemLabel
    ) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.industrialControlRule(for: colorScheme))
                .frame(height: AppTheme.tabRuleThickness)

            HStack(alignment: .bottom, spacing: AppTheme.tabSpacing) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection

                    Button {
                        withAnimation(reduceMotion ? nil : AppTheme.interfaceSpring) {
                            selection = option
                        }
                    } label: {
                        label(option)
                            .font(AppTheme.body)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.tabHeight)
                            .padding(.horizontal, AppTheme.gridUnit * 2)
                            .background {
                                if isSelected {
                                    NULTabShape(slant: AppTheme.tabSlant)
                                        .fill(AppTheme.workspaceBackground(for: colorScheme))
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if !isSelected {
                                    Rectangle()
                                        .fill(AppTheme.industrialControlRule(for: colorScheme))
                                        .frame(height: AppTheme.tabRuleThickness)
                                        .padding(.horizontal, AppTheme.gridUnit)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.tabHeight, alignment: .bottom)
                    .contentShape(NULTabShape(slant: AppTheme.tabSlant))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .zIndex(isSelected ? 1 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.tabHeight, alignment: .bottom)
        .background(AppTheme.sidebarBackground(for: colorScheme))
    }
}

private struct NULTabShape: Shape {
    let slant: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        let inset = min(max(slant, 0), rect.width / 3)
        var path = Path()
        path.move(to: CGPoint(x: inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
