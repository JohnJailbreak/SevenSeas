import SwiftUI
import UIKit

enum SettingsPage: Hashable {
    case root
    case networkName
    case password
    case security
    case band
    case maxDevices
    case autoDisable
    case theme
    case about
    case licenses
}

struct SettingsPanel: View {
    @EnvironmentObject var model: AppModel
    @State private var page: SettingsPage = .root

    var body: some View {
        ZStack(alignment: .topLeading) {
            if page == .root {
                rootPage
                    .transition(.move(edge: .leading))
            } else {
                subPage
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .animation(Anim.window, value: page)
    }

    // MARK: Root

    private var rootPage: some View {
        PanelTable {
            PanelHeaderCell(title: "Settings")
            networkGroup
            limitsGroup
            appGroup
            actionsGroup
            previewGroup
        }
    }

    private var networkGroup: some View {
        VStack(spacing: 0) {
            LinkRow(title: "Network Name", value: model.settings.ssid) { page = .networkName }
            LinkRow(title: "Password", value: String(repeating: "•", count: 10)) { page = .password }
            LinkRow(title: "Security", value: model.settings.security.title) { page = .security }
            LinkRow(title: "Band", value: model.settings.band.title) { page = .band }
            SwitchRow(title: "Hidden Network", isOn: $model.settings.hidden)
        }
    }

    private var limitsGroup: some View {
        VStack(spacing: 0) {
            PanelGap()
            LinkRow(title: "Max Devices", value: "\(model.settings.maxDevices)") { page = .maxDevices }
            LinkRow(title: "Auto-Disable", value: model.settings.autoDisable.shortTitle) { page = .autoDisable }
            SwitchRow(title: "Cellular Lockout", isOn: $model.settings.cellularLockout)
        }
    }

    private var appGroup: some View {
        VStack(spacing: 0) {
            PanelGap()
            LinkRow(title: "Theme", value: model.theme.name) { page = .theme }
            LinkRow(title: "About") { page = .about }
        }
    }

    private var actionsGroup: some View {
        VStack(spacing: 0) {
            PanelGap()
            ButtonCell(icon: "doc.on.doc", title: "Copy Password") { copyPassword() }
            ButtonCell(icon: "square.and.arrow.up", title: "Share Network") { shareNetwork() }
        }
    }

    private var previewGroup: some View {
        VStack(spacing: 0) {
            PanelGap()
            SwitchRow(title: "Simulate Upstream Loss", isOn: $model.simulateUpstreamLoss)
            ButtonCell(icon: "arrow.counterclockwise", title: "Replay Security Picker") {
                model.securityConfirmed = false
                Haptics.light()
            }
            PanelFooter(text: "Preview controls for this frontend build. The hotspot service is not connected yet, so every state is simulated.", height: 70)
        }
    }

    private func copyPassword() {
        UIPasteboard.general.string = model.settings.password
        Haptics.success()
    }

    private func shareNetwork() {
        ShareHelper.share(text: "Wi-Fi: \(model.settings.ssid)\nPassword: \(model.settings.password)")
    }

    // MARK: Pushed pages

    @ViewBuilder
    private var subPage: some View {
        switch page {
        case .root:
            EmptyView()
        case .networkName:
            TextPage(title: "Network Name", placeholder: "SevenSeas",
                     text: $model.settings.ssid,
                     footer: "This is the name other devices see when they look for Wi-Fi networks.",
                     back: { page = .root })
        case .password:
            PasswordPage(back: { page = .root })
        case .security:
            ChoicePage(title: "Security",
                       options: SecurityMode.allCases,
                       selected: model.settings.security,
                       label: { $0.title },
                       footer: "WPA3 is more secure. Choose WPA2 if an older device can't connect.",
                       back: { page = .root },
                       onSelect: { model.settings.security = $0 })
        case .band:
            ChoicePage(title: "Band",
                       options: BandChoice.allCases,
                       selected: model.settings.band,
                       label: { $0.title },
                       footer: "Automatic follows the upstream network. The radio shares one channel between the Wi-Fi you join and the hotspot you create.",
                       back: { page = .root },
                       onSelect: { model.settings.band = $0 })
        case .maxDevices:
            ChoicePage(title: "Max Devices",
                       options: Array(1...10),
                       selected: model.settings.maxDevices,
                       label: { "\($0)" },
                       footer: "New devices are turned away once this many are connected.",
                       back: { page = .root },
                       onSelect: { model.settings.maxDevices = $0 })
        case .autoDisable:
            ChoicePage(title: "Auto-Disable",
                       options: AutoDisable.allCases,
                       selected: model.settings.autoDisable,
                       label: { $0.title },
                       footer: "Turns sharing off by itself after this long.",
                       back: { page = .root },
                       onSelect: { model.settings.autoDisable = $0 })
        case .theme:
            ThemePage(back: { page = .root })
        case .about:
            AboutPage(back: { page = .root }, openLicenses: { page = .licenses })
        case .licenses:
            LicensesPage(back: { page = .about })
        }
    }
}
