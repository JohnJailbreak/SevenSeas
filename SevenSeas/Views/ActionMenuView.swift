import SwiftUI

struct MenuItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let chevron: Bool
    let enabled: Bool
    let action: () -> Void
}

/// Dopamine's four-row action menu: rows of `rowHeight`, 5 pt above and below,
/// icons 19 pt Medium, titles 17 pt, separators 1 pt at 30% grey.
struct ActionMenuView: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    private var items: [MenuItem] {
        return [
            MenuItem(id: 0, icon: "gearshape", title: "Settings", chevron: true, enabled: true,
                     action: { model.open(.settings) }),
            MenuItem(id: 1, icon: "laptopcomputer", title: "Devices", chevron: true, enabled: true,
                     action: { model.open(.devices) }),
            MenuItem(id: 2, icon: "arrow.clockwise", title: "Restart Hotspot", chevron: false,
                     enabled: model.sharing != .idle, action: { model.restartTapped() }),
            MenuItem(id: 3, icon: "chart.bar", title: "Status", chevron: true, enabled: true,
                     action: { model.open(.status) })
        ]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(model.theme.menu)
            ForEach(items) { item in
                MenuRowView(item: item, width: layout.columnWidth - 2 * Metrics.menuSidePadding, height: layout.rowHeight)
                    .offset(x: Metrics.menuSidePadding,
                            y: Metrics.menuVerticalPadding + CGFloat(item.id) * layout.rowHeight)
            }
            ForEach(0..<3) { index in
                Capsule()
                    .fill(Color.ssSeparator)
                    .frame(width: layout.columnWidth - 60, height: 1)
                    .offset(x: 30,
                            y: Metrics.menuVerticalPadding + CGFloat(index + 1) * layout.rowHeight - 1)
            }
        }
    }
}

struct MenuRowView: View {
    let item: MenuItem
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 9.2) {
                Image(systemName: item.icon)
                    .font(.system(size: 19, weight: .medium))
                Text(item.title)
                    .font(.system(size: 17))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .padding(.leading, 11.5)
            .frame(width: width, height: height, alignment: .leading)
            .overlay(chevronOverlay, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimOnPressStyle())
        .disabled(!item.enabled)
        .opacity(item.enabled ? 1.0 : 0.45)
    }

    @ViewBuilder
    private var chevronOverlay: some View {
        if item.chevron {
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.6))
                .padding(.trailing, 6)
        }
    }
}
