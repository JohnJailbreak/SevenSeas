import SwiftUI
import UIKit

enum SharingState {
    case idle
    case sharing
    case paused
}

/// The big button grows into this sheet.
enum SheetStage {
    case closed
    case picker
    case working
}

enum AppWindow: Equatable {
    case closed
    case settings
    case devices
    case status
}

enum LogState: Equatable {
    case running
    case done
    case final
}

struct LogLine: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var state: LogState
}

/// All frontend state. Everything that touches the radio is simulated for now.
///
/// To connect the real hotspot service later, replace the body of `runStartSequence`
/// (progress lines, failure handling), `stopSharing`, the upstream-loss handling in
/// `applyUpstreamSimulation`, and the `devices` list with live data. The views only read
/// the published properties below.
final class AppModel: ObservableObject {
    // MARK: Hotspot state
    @Published var sharing: SharingState = .idle
    @Published var sheet: SheetStage = .closed
    @Published var sheetTitle: String = "Starting Hotspot"
    @Published var log: [LogLine] = []
    @Published var window: AppWindow = .closed

    // MARK: Saved settings
    @Published var settings: HotspotSettings {
        didSet { settings.save() }
    }
    @Published var themeID: String {
        didSet { UserDefaults.standard.set(themeID, forKey: "sevenseas.theme") }
    }
    @Published var securityConfirmed: Bool {
        didSet { UserDefaults.standard.set(securityConfirmed, forKey: "sevenseas.securityConfirmed") }
    }

    // MARK: Preview data
    @Published var devices: [Device] = Device.samples
    @Published var simulateUpstreamLoss: Bool = false {
        didSet { applyUpstreamSimulation() }
    }
    @Published var upstreamName: String = "Home Wi-Fi"
    @Published var upstreamBand: String = "5 GHz"
    @Published var signal: Double = 0.84
    @Published var dataUsed: String = "1.4 GB"

    private var autoDisableTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        self.settings = HotspotSettings.load()
        self.themeID = defaults.string(forKey: "sevenseas.theme") ?? Theme.all[0].id
        self.securityConfirmed = defaults.bool(forKey: "sevenseas.securityConfirmed")
    }

    // MARK: Derived values
    var theme: Theme {
        return Theme.all.first(where: { $0.id == themeID }) ?? Theme.all[0]
    }

    var liveDevices: [Device] {
        if sharing == .idle { return [] }
        return devices.filter { $0.connected && !$0.blocked }
    }

    var blockedDevices: [Device] {
        return devices.filter { $0.blocked }
    }

    var headerLine1: String {
        switch sharing {
        case .idle:
            return "Wi-Fi to Wi-Fi sharing"
        case .sharing:
            let count = liveDevices.count
            return "Sharing with \(count) \(count == 1 ? "device" : "devices")"
        case .paused:
            return "Sharing paused"
        }
    }

    var primaryIcon: String {
        switch sharing {
        case .idle: return "wifi"
        case .sharing: return "wifi.slash"
        case .paused: return "wifi.slash"
        }
    }

    var primaryTitle: String {
        switch sharing {
        case .idle: return "Start Sharing"
        case .sharing: return "Stop Sharing"
        case .paused: return "Waiting for Wi-Fi"
        }
    }

    var statusTitle: String {
        switch sharing {
        case .idle: return "Ready"
        case .sharing: return "Sharing"
        case .paused: return "Paused"
        }
    }

    var statusSubtitle: String {
        return sharing == .paused ? "Waiting for Wi-Fi" : "Upstream signal"
    }

    var ringValue: Double {
        return sharing == .paused ? 0.0 : signal
    }

    var hotspotBandText: String {
        return settings.band == .automatic ? upstreamBand : settings.band.title
    }

    // MARK: Devices (all lookups go through the id, so a removed row can never be indexed)
    func deviceName(_ id: UUID) -> String {
        return devices.first(where: { $0.id == id })?.name ?? ""
    }

    func rename(_ id: UUID, to name: String) {
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index].name = name
        }
    }

    func toggleBlocked(_ id: UUID) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].blocked.toggle()
        if devices[index].blocked {
            devices[index].connected = false
        }
    }

    func forget(_ id: UUID) {
        devices.removeAll(where: { $0.id == id })
    }

    // MARK: Windows
    func open(_ target: AppWindow) {
        guard sheet == .closed else { return }
        Haptics.light()
        withAnimation(Anim.window) { window = target }
    }

    func closeWindow() {
        withAnimation(Anim.window) { window = .closed }
    }

    // MARK: Start, stop, restart
    func primaryTapped() {
        switch sharing {
        case .idle: startTapped()
        case .sharing: stopSharing()
        case .paused: break
        }
    }

    func startTapped() {
        guard sharing == .idle, sheet == .closed else { return }
        Haptics.light()
        sheetTitle = "Starting Hotspot"
        log = []
        if securityConfirmed {
            runStartSequence(title: "Starting Hotspot")
        } else {
            withAnimation(Anim.sheet) { sheet = .picker }
        }
    }

    func continueFromPicker() {
        guard sheet == .picker else { return }
        Haptics.light()
        securityConfirmed = true
        runStartSequence(title: "Starting Hotspot")
    }

    func restartTapped() {
        guard sharing != .idle, sheet == .closed else { return }
        Haptics.light()
        autoDisableTask?.cancel()
        runStartSequence(title: "Restarting Hotspot")
    }

    func stopSharing() {
        Haptics.light()
        autoDisableTask?.cancel()
        withAnimation(Anim.sheet) { sharing = .idle }
    }

    private func runStartSequence(title: String) {
        sheetTitle = title
        log = []
        withAnimation(Anim.sheet) { sheet = .working }

        Task { @MainActor in
            let steps: [String] = [
                "Checking upstream Wi-Fi",
                "Reading radio capabilities",
                "Verifying concurrency",
                "Checking channel width",
                "Choosing hotspot channel",
                "Starting access point",
                "Waiting for the radio",
                "Configuring DHCP",
                "Configuring routes",
                "Pinning DNS to en0",
                "Locking out cellular",
                "Verifying egress"
            ]
            for step in steps {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.log.append(LogLine(text: step, state: .running))
                }
                try? await Task.sleep(nanoseconds: 450_000_000)
                if let last = self.log.indices.last {
                    self.log[last].state = .done
                }
                Haptics.light()
            }
            withAnimation(.easeOut(duration: 0.3)) {
                self.log.append(LogLine(text: "SevenSeas is sharing", state: .final))
            }
            self.sheetTitle = "Done"
            Haptics.success()
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(Anim.sheet) {
                self.sheet = .closed
                self.sharing = self.simulateUpstreamLoss ? .paused : .sharing
            }
            self.scheduleAutoDisable()
        }
    }

    private func scheduleAutoDisable() {
        autoDisableTask?.cancel()
        let seconds = settings.autoDisable.rawValue
        if seconds <= 0 { return }
        autoDisableTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            if !Task.isCancelled && self.sharing != .idle {
                self.stopSharing()
            }
        }
    }

    private func applyUpstreamSimulation() {
        withAnimation(Anim.press) {
            if simulateUpstreamLoss && sharing == .sharing {
                sharing = .paused
            } else if !simulateUpstreamLoss && sharing == .paused {
                sharing = .sharing
            }
        }
    }
}
