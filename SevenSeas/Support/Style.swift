import SwiftUI
import UIKit

extension Color {
    /// 0xAARRGGBB, the same format Dopamine's Themes.plist uses.
    init(argb: UInt32) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// 0xRRGGBB, fully opaque.
    init(rgb: UInt32) {
        self.init(argb: 0xFF00_0000 | rgb)
    }

    static let ssSecondary = Color(.sRGB, red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, opacity: 0.6)
    static let ssTertiary = Color(.sRGB, red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, opacity: 0.3)
    static let ssBlue = Color(.sRGB, red: 10.0 / 255.0, green: 132.0 / 255.0, blue: 255.0 / 255.0, opacity: 1.0)
    static let ssGreen = Color(.sRGB, red: 71.0 / 255.0, green: 169.0 / 255.0, blue: 135.0 / 255.0, opacity: 1.0)
    static let ssSeparator = Color(.sRGB, white: 0.6, opacity: 0.3)
}

/// Animation curves taken from Dopamine's controllers.
enum Anim {
    /// The jailbreak button growing into the log sheet.
    static let sheet = Animation.spring(response: 0.75, dampingFraction: 0.9)
    /// Windows and in-window pushes.
    static let window = Animation.spring(response: 0.6, dampingFraction: 0.9)
    static let press = Animation.easeOut(duration: 0.15)
}

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Dims the label while pressed, like Dopamine's buttons.
struct DimOnPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1.0)
            .animation(Anim.press, value: configuration.isPressed)
    }
}

enum ShareHelper {
    static func share(text: String) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        while let presented = top.presentedViewController {
            top = presented
        }
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        top.present(controller, animated: true)
    }

    static func open(_ string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
}
