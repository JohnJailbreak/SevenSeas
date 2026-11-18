import SwiftUI

struct MainScreen: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        let open = model.sheet != .closed
        ZStack(alignment: .topLeading) {
            HeaderView(layout: layout)
                .offset(x: layout.columnX, y: layout.headerTop + (open ? -25 : 0))

            ActionMenuView(layout: layout)
                .frame(width: layout.columnWidth, height: layout.menuHeight)
                .scaleEffect(open ? 0.6 : 1.0)
                .opacity(open ? 0.0 : 1.0)
                .allowsHitTesting(!open)
                .offset(x: layout.columnX, y: layout.menuTop + (open ? -75 : 0))

            if model.sharing == .paused && !open {
                UpstreamNotice(layout: layout)
            }

            ExpandingButton(layout: layout)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        .animation(Anim.sheet, value: model.sheet)
    }
}

/// Wordmark, then two 14 pt lines. Inset 5 pt from the column like Dopamine's header.
struct HeaderView: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        let line = lineHeight(14)
        ZStack(alignment: .topLeading) {
            Image("Wordmark")
                .offset(x: 5, y: -Metrics.titleDrawnHigher)
            Text(model.headerLine1)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .offset(x: 5, y: Metrics.titleSlot + 2)
            Text("by \(AppInfo.author)")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))
                .offset(x: 5, y: Metrics.titleSlot + 2 + line + 2)
        }
        .frame(width: layout.columnWidth, height: layout.headerHeight, alignment: .topLeading)
        .shadow(color: model.theme.titleShadow ? Color.black.opacity(0.3) : Color.clear, radius: 30, x: 0, y: 0)
    }
}

/// Sits in the slot Dopamine uses for "Update Available".
struct UpstreamNotice: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        Button(action: { model.open(.status) }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 19, weight: .medium))
                Text("Upstream Wi-Fi Lost")
                    .font(.system(size: 17))
            }
            .foregroundColor(.white)
            .frame(width: layout.columnWidth, height: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
        .offset(x: layout.columnX, y: layout.buttonTop - 20 - 30)
    }
}
