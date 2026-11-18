import SwiftUI

/// Dopamine-style modal window: 330 pt wide, 70% of the screen tall, rounded 16 pt, tinted by the
/// theme's window colour. Tapping outside closes it.
struct WindowHost: View {
    @EnvironmentObject var model: AppModel
    let size: CGSize

    var body: some View {
        let panelHeight: CGFloat = size.height * (size.height < 618 ? 0.8 : 0.7)
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { model.closeWindow() }
            panelContent
                .frame(width: size.width - 2 * Metrics.sideMargin, height: panelHeight, alignment: .topLeading)
                .background(model.theme.window)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.windowRadius, style: .continuous))
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var panelContent: some View {
        switch model.window {
        case .settings:
            SettingsPanel()
        case .devices:
            DevicesPanel()
        case .status:
            StatusPanel()
        case .closed:
            EmptyView()
        }
    }
}

/// Scrolling table inset 12 pt from the window edge, 306 pt wide, 5 pt of padding on top.
struct PanelTable<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                content
            }
            .frame(width: Metrics.tableWidth, alignment: .topLeading)
            .padding(.top, 5)
            .padding(.bottom, 24)
        }
        .frame(width: Metrics.tableWidth)
        .offset(x: Metrics.tableX)
    }
}

// MARK: Headers

/// Title centred in a 60 pt cell with a 1 pt line near the bottom. Used by root panels.
struct PanelHeaderCell: View {
    let title: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(width: Metrics.tableWidth, alignment: .center)
                .offset(y: 27 - lineHeight(17, .medium) / 2)
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 266, height: 1)
                .offset(x: 20, y: 57)
        }
        .frame(width: Metrics.tableWidth, height: 60, alignment: .topLeading)
    }
}

/// Same, with a back chevron, for pages pushed inside a panel.
struct PanelNavHeader: View {
    let title: String
    let back: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: Metrics.tableWidth - 100, alignment: .center)
                .offset(x: 50, y: 27 - lineHeight(17, .medium) / 2)
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 266, height: 1)
                .offset(x: 20, y: 57)
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(DimOnPressStyle())
            .offset(x: 10, y: 13)
        }
        .frame(width: Metrics.tableWidth, height: 70, alignment: .topLeading)
    }
}

struct PanelGap: View {
    var height: CGFloat = 35

    var body: some View {
        Color.clear.frame(width: Metrics.tableWidth, height: height)
    }
}

struct PanelFooter: View {
    let text: String
    var height: CGFloat = 44

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color.ssSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .frame(width: Metrics.tableWidth, alignment: .topLeading)
            .frame(minHeight: height, alignment: .topLeading)
    }
}

// MARK: Rows

/// Label on the left, optional value and chevron on the right. Optional second line (14 pt).
struct LinkRow: View {
    let title: String
    let value: String?
    let subtitle: String?
    let height: CGFloat
    let action: () -> Void

    init(title: String, value: String? = nil, subtitle: String? = nil, height: CGFloat = 44, action: @escaping () -> Void) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if let value = value {
                    Text(value)
                        .font(.system(size: 17))
                        .foregroundColor(Color.ssSecondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ssTertiary)
                    .frame(width: 17, height: 17)
                    .padding(.leading, 2)
            }
            .padding(.leading, 32)
            .padding(.trailing, 25)
            .frame(width: Metrics.tableWidth, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
    }
}

/// A row that only shows information: no chevron, no press state.
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 17))
                .foregroundColor(Color.ssSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 32)
        .frame(width: Metrics.tableWidth, height: 44)
    }
}

struct SwitchRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.ssGreen))
        }
        .padding(.horizontal, 32)
        .frame(width: Metrics.tableWidth, height: 44)
    }
}

struct CheckRow: View {
    let title: String
    let checked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if checked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.ssBlue)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.leading, 32)
            .padding(.trailing, 30)
            .frame(width: Metrics.tableWidth, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
    }
}

/// Outlined button inside a 44 pt cell: 266 x 36, 1 pt border at 15% white.
struct ButtonCell: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                Text(title)
                    .font(.system(size: 17))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .frame(width: 266, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
        .frame(width: Metrics.tableWidth, height: 44)
    }
}

struct PanelTextField: View {
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(size: 17))
        .foregroundColor(.white)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .padding(.horizontal, 32)
        .frame(width: Metrics.tableWidth, height: 44)
    }
}
