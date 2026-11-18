import SwiftUI

/// The bottom button. When sharing starts it grows into a full-width sheet (the
/// start log or the security picker), the same way Dopamine's jailbreak button does.
struct ExpandingButton: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        let open = model.sheet != .closed
        let sheetHeight: CGFloat = layout.size.height - layout.sheetTop + 100
        let width: CGFloat = open ? layout.size.width : layout.columnWidth
        let height: CGFloat = open ? sheetHeight : Metrics.buttonHeight
        let originX: CGFloat = open ? 0 : layout.columnX
        let originY: CGFloat = open ? layout.sheetTop : layout.buttonTop
        let disabled = model.sharing == .paused

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(model.theme.menu)
                .frame(width: width, height: height)

            if open {
                SheetContent(layout: layout)
                    .transition(.opacity)
            } else {
                Button(action: { model.primaryTapped() }) {
                    HStack(spacing: 10) {
                        Image(systemName: model.primaryIcon)
                            .font(.system(size: 19, weight: .medium))
                        Text(model.primaryTitle)
                            .font(.system(size: 17))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .frame(width: layout.columnWidth, height: Metrics.buttonHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DimOnPressStyle())
                .disabled(disabled)
                .transition(.opacity)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
        .opacity((!open && disabled) ? 0.7 : 1.0)
        .offset(x: originX, y: originY)
    }
}

/// What lives inside the expanded sheet. Coordinates are relative to the sheet's top left.
struct SheetContent: View {
    @EnvironmentObject var model: AppModel
    let layout: MainLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            titleRow
            if model.sheet == .picker {
                SecurityPicker(layout: layout)
            } else {
                LyricsLog(layout: layout)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height - layout.sheetTop + 100, alignment: .topLeading)
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            HelixIndicator()
            Text(model.sheetTitle)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .frame(width: layout.size.width, height: lineHeight(18), alignment: .center)
        .offset(y: 20)
    }
}
