import SwiftUI

struct StatusPanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        PanelTable {
            PanelHeaderCell(title: "Status")
            summary
            PanelGap(height: 20)
            LinkRow(title: "Upstream", value: model.upstreamName) { model.open(.settings) }
            LinkRow(title: "Hotspot", value: "\(model.settings.ssid) · \(model.hotspotBandText)") { model.open(.settings) }
            LinkRow(title: "Devices", value: "\(model.liveDevices.count) of \(model.settings.maxDevices)") { model.open(.devices) }
            InfoRow(title: "Data Used", value: model.dataUsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var summary: some View {
        VStack(spacing: 0) {
            Text(model.statusTitle)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            Text(model.statusSubtitle)
                .font(.system(size: 18))
                .foregroundColor(Color.white.opacity(0.5))
            Color.clear.frame(width: 1, height: 20)
            ProgressRing(progress: model.ringValue)
        }
        .padding(.top, 22)
        .frame(width: Metrics.tableWidth)
    }
}

/// Dopamine's update ring, reused for the upstream signal: 150 pt, 10 pt stroke, round caps.
struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 29, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(5)
        .frame(width: 150, height: 150)
        .animation(Anim.window, value: progress)
    }
}
