import SwiftUI

// MARK: Text entry

struct TextPage: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let footer: String
    let back: () -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: title, back: back)
            PanelGap(height: 20)
            PanelTextField(placeholder: placeholder, text: $text)
            PanelFooter(text: footer, height: 60)
        }
    }
}

struct PasswordPage: View {
    @EnvironmentObject var model: AppModel
    @State private var reveal = false
    let back: () -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: "Password", back: back)
            PanelGap(height: 20)
            PanelTextField(placeholder: "Password", text: $model.settings.password, secure: !reveal)
            SwitchRow(title: "Show Password", isOn: $reveal)
            PanelGap(height: 20)
            ButtonCell(icon: "shuffle", title: "Generate Random Password") {
                model.settings.password = HotspotSettings.randomPassword()
                Haptics.light()
            }
            PanelFooter(text: "Use at least 8 characters.", height: 44)
        }
    }
}

// MARK: Single choice

struct ChoicePage<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let selected: Option
    let label: (Option) -> String
    let footer: String
    let back: () -> Void
    let onSelect: (Option) -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: title, back: back)
            PanelGap(height: 20)
            ForEach(options, id: \.self) { option in
                CheckRow(title: label(option), checked: option == selected) {
                    Haptics.light()
                    onSelect(option)
                }
            }
            PanelFooter(text: footer, height: 60)
        }
    }
}

// MARK: Theme

struct ThemePage: View {
    @EnvironmentObject var model: AppModel
    let back: () -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: "Theme", back: back)
            iconCell
            PanelGap(height: 20)
            ForEach(Theme.all) { theme in
                ThemeRow(theme: theme, selected: theme.id == model.themeID) {
                    Haptics.light()
                    model.themeID = theme.id
                }
            }
            PanelFooter(text: "Every theme uses the Lighthouse Beam icon, whose background is Morning Haze's sky.", height: 44)
        }
    }

    private var iconCell: some View {
        HStack(spacing: 14) {
            Image("IconPreview")
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 13.4, style: .continuous))
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 0) {
                Text("Lighthouse Beam")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                Text("App icon, drawn from Morning Haze")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 32)
        .padding(.top, 12)
        .frame(width: Metrics.tableWidth, alignment: .leading)
    }
}

struct ThemeRow: View {
    let theme: Theme
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(theme.thumbName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                Text(theme.name)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if selected {
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

// MARK: About

struct AboutPage: View {
    let back: () -> Void
    let openLicenses: () -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: "About", back: back)
            hero
            PanelGap(height: 20)
            LinkRow(title: "Made by \(AppInfo.author)") { ShareHelper.open(AppInfo.authorURL) }
            LinkRow(title: "Interface by Dopamine", subtitle: "opa334 and contributors · MIT", height: 56) { ShareHelper.open(AppInfo.dopamineURL) }
            InfoRow(title: "Lighthouse Beam icon", value: "")
            LinkRow(title: "Open-source licenses") { openLicenses() }
        }
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Image("IconPreview")
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 21.5, style: .continuous))
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
            Image("Wordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 27.5)
                .padding(.top, 8)
            Text("Version \(AppInfo.version) (\(AppInfo.build))")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))
        }
        .padding(.top, 22)
        .frame(width: Metrics.tableWidth)
    }
}

struct LicensesPage: View {
    let back: () -> Void

    var body: some View {
        PanelTable {
            PanelNavHeader(title: "Licenses", back: back)
            Text(AppInfo.licenseText)
                .font(.system(size: 12))
                .foregroundColor(Color.ssSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(width: Metrics.tableWidth, alignment: .topLeading)
        }
    }
}
