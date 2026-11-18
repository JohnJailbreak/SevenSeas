import Foundation

enum SecurityMode: String, Codable, CaseIterable {
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"

    var title: String { return rawValue }
}

enum BandChoice: String, Codable, CaseIterable {
    case automatic = "Automatic"
    case band24 = "2.4 GHz"
    case band5 = "5 GHz"

    var title: String { return rawValue }
}

enum AutoDisable: Int, Codable, CaseIterable {
    case never = 0
    case min15 = 900
    case min30 = 1800
    case hour1 = 3600
    case hour2 = 7200
    case hour4 = 14400
    case hour8 = 28800

    var title: String {
        switch self {
        case .never: return "Never"
        case .min15: return "After 15 minutes"
        case .min30: return "After 30 minutes"
        case .hour1: return "After 1 hour"
        case .hour2: return "After 2 hours"
        case .hour4: return "After 4 hours"
        case .hour8: return "After 8 hours"
        }
    }

    var shortTitle: String {
        switch self {
        case .never: return "Never"
        case .min15: return "15 min"
        case .min30: return "30 min"
        case .hour1: return "1 hour"
        case .hour2: return "2 hours"
        case .hour4: return "4 hours"
        case .hour8: return "8 hours"
        }
    }
}

struct HotspotSettings: Codable, Equatable {
    var ssid: String = "SevenSeas"
    var password: String = HotspotSettings.randomPassword()
    var security: SecurityMode = .wpa3
    var band: BandChoice = .automatic
    var hidden: Bool = false
    var maxDevices: Int = 5
    var autoDisable: AutoDisable = .never
    var cellularLockout: Bool = true
    var knownDevicesOnly: Bool = false

    private static let storageKey = "sevenseas.settings.v1"

    static func load() -> HotspotSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(HotspotSettings.self, from: data) else {
            return HotspotSettings()
        }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: HotspotSettings.storageKey)
        }
    }

    static func randomPassword(length: Int = 14) -> String {
        let alphabet = Array("abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        var result = ""
        for _ in 0..<length {
            result.append(alphabet.randomElement() ?? "x")
        }
        return result
    }
}

struct Device: Identifiable, Equatable {
    let id: UUID
    var name: String
    let ip: String
    let mac: String
    var connected: Bool
    var blocked: Bool

    init(id: UUID = UUID(), name: String, ip: String, mac: String, connected: Bool = true, blocked: Bool = false) {
        self.id = id
        self.name = name
        self.ip = ip
        self.mac = mac
        self.connected = connected
        self.blocked = blocked
    }

    /// Preview data for the frontend build. Replace with the real station list from the hotspot service.
    static let samples: [Device] = [
        Device(name: "Parv's MacBook", ip: "192.168.4.2", mac: "A4:83:E7:2B:19:C0"),
        Device(name: "iPad", ip: "192.168.4.3", mac: "3C:22:FB:90:4E:11"),
        Device(name: "Living Room TV", ip: "192.168.4.4", mac: "7C:2F:80:11:AB:36"),
        Device(name: "Unknown Android", ip: "192.168.4.9", mac: "DC:A6:32:0F:55:7A", connected: false, blocked: true)
    ]
}
