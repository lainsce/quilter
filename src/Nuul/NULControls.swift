import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Compact Metro switch used by visible settings controls.
///
/// The accent comes from the app environment so the track, thumb, and motion
/// stay consistent with Quilter's shared palette.
/// The control remains intrinsic-width so parent rows can align it explicitly.
struct NULToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        Button {
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(AppTheme.interfaceSpring) {
                    configuration.isOn.toggle()
                }
            }
        } label: {
            HStack(spacing: 8) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            configuration.isOn
                                ? accentColor
                                : Color.primary.opacity(0.05)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .strokeBorder(AppTheme.industrialControlRule(for: colorScheme), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .strokeBorder(AppTheme.industrialControlRule(for: colorScheme), lineWidth: 1)
                        }
                        .frame(width: 24, height: 24)
                        .padding(4)
                }
                .frame(width: 48, height: 32)
                .animation(
                    reduceMotion ? nil : AppTheme.interfaceSpring,
                    value: configuration.isOn
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityRemoveTraits(.isButton)
        .accessibilityAddTraits(.isToggle)
    }
}

/// Simple two-column form row using flat, native controls.
struct NULFormRow<Control: View>: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let control: Control

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.description = description
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.formRowSpacing) {
            VStack(alignment: .leading, spacing: AppTheme.gridUnit) {
                titleLabel(alignment: .leading)
                if let description {
                    Text(description)
                        .font(AppTheme.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: AppTheme.formLabelWidth, alignment: .leading)

            control
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func titleLabel(alignment: TextAlignment) -> some View {
        Text(title)
            .font(AppTheme.caption)
            .textCase(.uppercase)
            .kerning(0.4)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(alignment)
    }
}

/// Flat in-content action treatment backed by native button behavior.
struct NULButtonStyle: ButtonStyle {
    enum Kind { case primary, neutral, quiet }

    private let kind: Kind
    private let accentColor: Color
    private let horizontalPadding: CGFloat?
    private let labelColor: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(
        kind: Kind = .primary,
        accentColor: Color = AppTheme.accentColor,
        horizontalPadding: CGFloat? = nil,
        labelColor: Color? = nil
    ) {
        self.kind = kind
        self.accentColor = accentColor
        self.horizontalPadding = horizontalPadding
        self.labelColor = labelColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.contentBlockSubtitle)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(labelColor ?? (kind == .primary ? .black : .primary))
            .padding(
                .horizontal,
                horizontalPadding ?? (kind == .quiet ? AppTheme.gridUnit : AppTheme.gridUnit * 2)
            )
            .frame(minWidth: AppTheme.toolbarControlSize, minHeight: AppTheme.toolbarControlSize)
            .background(
                backgroundColor,
                in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
            )
            .overlay {
                if configuration.isPressed && kind != .quiet {
                    RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius)
                        .fill(Color.primary.opacity(0.10))
                }
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.84 : 1) : 0.42)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            accentColor
        case .neutral, .quiet:
            AppTheme.industrialSurface
        }
    }
}

/// Flat native field sizing modifier.
struct NULFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(minHeight: AppTheme.gridUnit * 9)
    }
}

/// Nuul's flat menu picker with a native disclosure affordance.
struct NULMenuPicker<Selection: Hashable, ItemLabel: View>: View {
    private let title: LocalizedStringKey
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel
    private let showsTitle: Bool

    init(
        _ title: LocalizedStringKey,
        selection: Binding<Selection>,
        options: [Selection],
        showsTitle: Bool = true,
        label: @escaping (Selection) -> ItemLabel
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.showsTitle = showsTitle
        self.label = label
    }

    var body: some View {
        Menu {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    selection = option
                } label: {
                    label(option)
                }
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        } label: {
            HStack(spacing: AppTheme.gridUnit * 2) {
                if showsTitle {
                    Text(title)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                }

                label(selection)
                    .lineLimit(1)
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: AppTheme.toolbarControlSize, alignment: .leading)
            .padding(.horizontal, AppTheme.gridUnit * 2)
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel(Text(title))
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// SwiftUI's native segmented picker.
struct NULSegmentedPicker<Selection: Hashable, ItemLabel: View>: View {
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(selection: Binding<Selection>, options: [Selection], label: @escaping (Selection) -> ItemLabel) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    withAnimation(reduceMotion ? nil : AppTheme.interfaceSpring) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .font(AppTheme.body)
                        .foregroundStyle(option == selection ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.toolbarControlSize)
                        .padding(.horizontal, AppTheme.gridSmallGap)
                        .background {
                            RoundedRectangle(cornerRadius: AppTheme.gridUnit / 2, style: .continuous)
                                .fill(option == selection ? Color.primary.opacity(0.12) : .clear)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(AppTheme.gridUnit / 2)
        .background(AppTheme.industrialSurface, in: .rect(cornerRadius: AppTheme.industrialCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius, style: .continuous)
                .strokeBorder(AppTheme.industrialControlRule(for: colorScheme), lineWidth: 1)
        }
    }
}

#if os(macOS)
/// The sidebar is an opaque navigation surface. Its contents stay flat on top
/// of it rather than adding a second visual-effect layer.
struct NULSidebarSurface: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.sidebarBackground(for: colorScheme)
            .ignoresSafeArea(.container, edges: .top)
    }
}
#endif

/// Flat text field style that keeps the control legible without a heavy card.
struct NULTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTheme.body)
            .padding(.horizontal, AppTheme.fieldHorizontalPadding)
            .frame(minHeight: AppTheme.fieldHeight)
            .textFieldStyle(.plain)
            .background(
                AppTheme.industrialSurface,
                in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius)
                    .strokeBorder(AppTheme.industrialControlRule(for: colorScheme), lineWidth: 2)
            }
            .opacity(isEnabled ? 1 : 0.42)
    }
}

struct NULIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
            .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
            .accessibilityHidden(true)
    }
}

/// Nuul toolbar button with a 38-point hit area.
struct NULToolbarButtonStyle: ButtonStyle {
    let showsSurface: Bool

    init(showsSurface: Bool = true) {
        self.showsSurface = showsSurface
    }

    func makeBody(configuration: Configuration) -> some View {
        NULButtonBody(configuration: configuration, showsSurface: showsSurface)
    }
}

/// Keeps sidebar row activation native while still providing a restrained
/// pressed response. Press state comes from SwiftUI's button configuration;
/// a competing zero-distance drag gesture would delay the primary click.
struct QuilterSidebarRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct NULButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let showsSurface: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
            .frame(width: AppTheme.toolbarIconSize, height: AppTheme.toolbarIconSize)
            .frame(width: AppTheme.toolbarControlSize, height: AppTheme.toolbarControlSize)
            .contentShape(Rectangle())
            .background {
                if showsSurface {
                    RoundedRectangle(cornerRadius: AppTheme.industrialCornerRadius)
                        .fill(AppTheme.industrialPanel)
                }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.42)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : AppTheme.interfaceSpring, value: configuration.isPressed)
    }
}

/// Nuul toolbar group sizing without a custom material surface.
struct NULToolbarSurface: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .frame(height: AppTheme.toolbarControlSize)
            .background(
                AppTheme.industrialPanel,
                in: .rect(cornerRadius: AppTheme.industrialCornerRadius)
            )
            .opacity(isVisible ? 1 : 0)
    }
}

extension View {
    func nulToolbarControlSurface(isVisible: Bool) -> some View {
        modifier(NULToolbarSurface(isVisible: isVisible))
    }
}
