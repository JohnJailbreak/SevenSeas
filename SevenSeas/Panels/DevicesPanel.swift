import SwiftUI

enum DevicesPage: Equatable {
    case root
    case blocked
    case device(UUID)
}

struct DevicesPanel: View {
    @EnvironmentObject var model: AppModel
    @State private var page: DevicesPage = .root
    /// Where the device page's back chevron returns to.
    @State private var cameFrom: DevicesPage = .root

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
            PanelHeaderCell(title: "Devices")
            deviceList
            PanelGap()
            SwitchRow(title: "Known Devices Only", isOn: $model.settings.knownDevicesOnly)
            LinkRow(title: "Blocked Devices", value: "\(model.blockedDevices.count)") {
                page = .blocked
            }
            PanelFooter(text: "Tap a device to rename, block or remove it. Names are saved by MAC address.", height: 50)
        }
    }

    @ViewBuilder
    private var deviceList: some View {
        if model.liveDevices.isEmpty {
            Text(model.sharing == .idle ? "Devices show up here once sharing starts." : "No devices connected.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))
                .frame(width: Metrics.tableWidth, height: 56)
        } else {
            VStack(spacing: 0) {
                ForEach(model.liveDevices) { device in
                    LinkRow(title: device.name, subtitle: "\(device.ip) · \(device.mac)", height: 56) {
                        cameFrom = .root
                        page = .device(device.id)
                    }
                }
            }
        }
    }

    // MARK: Pushed pages

    @ViewBuilder
    private var subPage: some View {
        switch page {
        case .root:
            EmptyView()
        case .blocked:
            blockedPage
        case .device(let id):
            devicePage(id)
        }
    }

    private var blockedPage: some View {
        PanelTable {
            PanelNavHeader(title: "Blocked Devices", back: { page = .root })
            PanelGap(height: 20)
            ForEach(model.blockedDevices) { device in
                LinkRow(title: device.name, subtitle: "\(device.ip) · \(device.mac)", height: 56) {
                    cameFrom = .blocked
                    page = .device(device.id)
                }
            }
            PanelFooter(text: model.blockedDevices.isEmpty ? "No blocked devices." : "Blocked devices can't join, even with the password.", height: 44)
        }
    }

    @ViewBuilder
    private func devicePage(_ id: UUID) -> some View {
        if let device = model.devices.first(where: { $0.id == id }) {
            PanelTable {
                PanelNavHeader(title: device.name, back: { page = cameFrom })
                PanelGap(height: 20)
                PanelTextField(placeholder: "Name", text: nameBinding(id))
                InfoRow(title: "IP Address", value: device.ip)
                InfoRow(title: "MAC Address", value: device.mac)
                PanelGap(height: 20)
                ButtonCell(icon: device.blocked ? "checkmark.circle" : "nosign",
                           title: device.blocked ? "Unblock Device" : "Block Device") {
                    Haptics.light()
                    model.toggleBlocked(id)
                }
                ButtonCell(icon: "trash", title: "Forget Device") {
                    Haptics.light()
                    page = cameFrom
                    // Remove after the page has slid away.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        model.forget(id)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    private func nameBinding(_ id: UUID) -> Binding<String> {
        return Binding<String>(
            get: { model.deviceName(id) },
            set: { newValue in model.rename(id, to: newValue) }
        )
    }
}
