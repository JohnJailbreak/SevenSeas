import SwiftUI
import UIKit

enum Safe {
    static var insets: UIEdgeInsets {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
    }
}

/// Height of one line of the system font, as UIKit lays it out.
func lineHeight(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> CGFloat {
    return UIFont.systemFont(ofSize: size, weight: weight).lineHeight
}

enum Metrics {
    static let sideMargin: CGFloat = 30
    static let menuSidePadding: CGFloat = 20
    static let menuVerticalPadding: CGFloat = 5
    static let buttonHeight: CGFloat = 60
    static let cornerRadius: CGFloat = 14
    static let windowRadius: CGFloat = 16
    /// The wordmark sits in a 40 pt slot and is drawn 7 pt above it.
    static let titleSlot: CGFloat = 40
    static let titleDrawnHigher: CGFloat = 7
    /// Panel tables are inset 12 pt inside the 330 pt window.
    static let tableX: CGFloat = 12
    static let tableWidth: CGFloat = 306
}

/// DOMainViewController's layout: a centred column 73% of the screen height (78% on phones with
/// a home button), header on top, menu in the middle, the big button at the bottom, equal gaps.
struct MainLayout {
    let size: CGSize
    let homeButton: Bool
    let rowHeight: CGFloat
    let columnWidth: CGFloat
    let columnX: CGFloat
    let headerHeight: CGFloat
    let menuHeight: CGFloat
    let headerTop: CGFloat
    let menuTop: CGFloat
    let buttonTop: CGFloat
    let sheetTop: CGFloat
    let logBottomInset: CGFloat

    init(size: CGSize) {
        let insets = Safe.insets
        let home = (insets.bottom == 0)
        let row: CGFloat = size.height < 618 ? 52 : (home ? 65 : 73)
        let colHeight: CGFloat = size.height * (home ? 0.78 : 0.73)
        let centerY: CGFloat = size.height / 2 + max(15, insets.top - 20)
        let colTop: CGFloat = centerY - colHeight / 2
        let line: CGFloat = lineHeight(14)
        let headerH: CGFloat = Metrics.titleSlot + 2 + line + 2 + line
        let menuH: CGFloat = 4 * row + 2 * Metrics.menuVerticalPadding
        let gap: CGFloat = max(12, (colHeight - headerH - menuH - Metrics.buttonHeight) / 2)

        self.size = size
        self.homeButton = home
        self.rowHeight = row
        self.columnWidth = size.width - 2 * Metrics.sideMargin
        self.columnX = Metrics.sideMargin
        self.headerHeight = headerH
        self.menuHeight = menuH
        self.headerTop = colTop
        self.menuTop = colTop + headerH + gap
        self.buttonTop = colTop + headerH + gap + menuH + gap
        self.sheetTop = size.height * 0.26 + 35
        self.logBottomInset = home ? 50 : 80
    }
}
