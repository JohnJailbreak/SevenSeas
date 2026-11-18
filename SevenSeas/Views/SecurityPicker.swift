import SwiftUI

/// First-run WPA2 / WPA3 choice, shown inside the expanded sheet like Dopamine's package manager picker.
struct SecurityPicker: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        let sheetHeight: CGFloat = layout.size.height - layout.sheetTop
        let centerY: CGFloat = sheetHeight / 2 - 10
        let stackTop: CGFloat = centerY - 55
        let width: CGFloat = layout.size.width

        ZStack(alignment: .topLeading) {
            Text("Select Security")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: width, alignment: .center)
                .offset(y: stackTop - 30 - lineHeight(24, .medium))

            HStack(spacing: 0) {
                SecurityTile(mode: .wpa2)
                SecurityTile(mode: .wpa3)
            }
            .offset(x: width / 2 - 110, y: stackTop)

            Text("WPA3 is more secure. Choose WPA2 if an older device can't connect.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(width: 275)
                .offset(x: width / 2 - 137.5, y: stackTop + 110 + 15)

            Button(action: { model.continueFromPicker() }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 19, weight: .medium))
                    Text("Continue")
                        .font(.system(size: 17))
                }
                .foregroundColor(.white)
                .frame(width: width - 60, height: 50)
                .background(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous).fill(Color.white.opacity(0.2)))
                .contentShape(Rectangle())
            }
            .buttonStyle(DimOnPressStyle())
            .offset(x: 30, y: sheetHeight - 90)
        }
    }
}

struct SecurityTile: View {
    @EnvironmentObject var model: AppModel
    let mode: SecurityMode

    private var selected: Bool { return model.settings.security == mode }

    private var gradient: LinearGradient {
        let colors: [Color] = mode == .wpa2
            ? [Color(rgb: 0x6F8EA6), Color(rgb: 0x3A5568)]
            : [Color(rgb: 0x3FD1A5), Color(rgb: 0x0F7D7A)]
        return LinearGradient(colors: colors, startPoint: UnitPoint(x: 0.3, y: 0.0), endPoint: UnitPoint(x: 0.7, y: 1.0))
    }

    var body: some View {
        Button(action: {
            Haptics.light()
            model.settings.security = mode
        }) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12.3, style: .continuous)
                    .fill(gradient)
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12.3, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .overlay(Image(mode == .wpa2 ? "TileWPA2" : "TileWPA3"))

                HStack(spacing: 7) {
                    Text(mode.title)
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17))
                        .foregroundColor(selected ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 19, height: 19)
                }
                .foregroundColor(.white)
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: 110, height: 110)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
    }
}
