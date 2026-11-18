import SwiftUI

/// Dopamine's "lyrics" log: the newest line sits near the bottom, older lines move up 40 pt
/// at a time and get blurrier toward the top of the sheet.
struct LyricsLog: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        let count = model.log.count
        let newestTop: CGFloat = layout.size.height - layout.logBottomInset - layout.sheetTop
        ZStack(alignment: .topLeading) {
            ForEach(Array(model.log.enumerated()), id: \.element.id) { index, line in
                let top: CGFloat = newestTop - 40 * CGFloat(count - 1 - index)
                LogLineView(line: line)
                    .frame(width: layout.size.width - 50, height: 40, alignment: .leading)
                    .blur(radius: blurRadius(centerY: top + 20 + layout.sheetTop))
                    .offset(x: 25, y: top)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: count)
    }

    /// 0 pt near the bottom, 4 pt at the top of the sheet.
    private func blurRadius(centerY: CGFloat) -> CGFloat {
        let top = layout.sheetTop
        let bottom = layout.size.height - 125
        let t = 1 - (centerY - top) / (bottom - top)
        return 4 * min(1, max(0, t))
    }
}

struct LogLineView: View {
    let line: LogLine

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                icon
            }
            .frame(width: 30, height: 30)
            Text(line.text)
                .font(.system(size: line.state == .running ? 20 : 18))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .opacity(line.state == .running ? 0.9 : 0.5)
        .animation(.easeOut(duration: 0.2), value: line.state)
    }

    @ViewBuilder
    private var icon: some View {
        switch line.state {
        case .running:
            Spinner()
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 19))
        case .final:
            Image(systemName: "wifi")
                .font(.system(size: 19))
        }
    }
}

/// Dopamine's loading arc, one turn per second.
struct Spinner: View {
    @State private var spinning = false

    var body: some View {
        Image("Loading")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinning)
            .onAppear { spinning = true }
    }
}

/// Two rows of ten 2 pt dots that swap places in a wave, 2.3 s per cycle, each dot 0.1 s behind
/// the one to its left. The row that starts at the top is full white, the other 80%.
struct HelixIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<10 {
                    let s = t - 0.1 * Double(i)
                    let phase = 0.5 - 0.5 * cos(2.0 * Double.pi * s / 2.3)
                    let x = CGFloat(i) * 3
                    let upper = CGRect(x: x, y: CGFloat(8.0 * phase), width: 2, height: 2)
                    let lower = CGRect(x: x, y: CGFloat(8.0 - 8.0 * phase), width: 2, height: 2)
                    context.fill(Path(ellipseIn: upper), with: .color(Color.white))
                    context.fill(Path(ellipseIn: lower), with: .color(Color.white.opacity(0.8)))
                }
            }
        }
        .frame(width: 30, height: 12)
    }
}
