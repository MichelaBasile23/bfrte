import Foundation
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Themes feature.
///
extension WPStyleGuide {
    public struct Themes {
        public static func styleCurrentThemeButton(_ button: UIButton) {
            button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            button.setTitleColor(.label, for: UIControl.State())
            button.backgroundColor = .clear
        }

        // MARK: - Cell Styles

        public static let placeholderColor: UIColor = .neutral(.shade10)

        public static let activeCellBackgroundColor: UIColor = .neutral(.shade40)
        public static let activeCellNameColor: UIColor = .textInverted
        public static let activeCellInfoColor: UIColor = .primaryLight

        public static let inactiveCellBackgroundColor: UIColor = .listForeground
        public static let inactiveCellNameColor: UIColor = .neutral(.shade70)
        public static let inactiveCellPriceColor: UIColor = .success

        // MARK: - Metrics

        public static let currentBarLineHeight: CGFloat = 56
        public static let currentBarSeparator: CGFloat = 0.5

        public static func headerHeight(_ horizontallyCompact: Bool) -> CGFloat {
            var headerHeight = (currentBarSeparator * 2)
            if horizontallyCompact {
                headerHeight += (currentBarLineHeight * 2) + currentBarSeparator
            } else {
                headerHeight += currentBarLineHeight
            }
            return headerHeight
        }

        public static let columnMargin: CGFloat = 12
        public static let rowMargin: CGFloat = 12
        public static let minimumColumnWidth: CGFloat = 330

        public static let cellImageInset: CGFloat = 2
        public static let cellImageRatio: CGFloat = 0.75
        public static let cellInfoBarHeight: CGFloat = 55

        public static func cellWidthForFrameWidth(_ width: CGFloat) -> CGFloat {
            let numberOfColumns = max(1, trunc(width / minimumColumnWidth))
            let numberOfMargins = numberOfColumns + 1
            let marginsWidth = numberOfMargins * columnMargin
            let columnsWidth = width - marginsWidth
            let columnWidth = trunc(columnsWidth / numberOfColumns)
            return columnWidth
        }

        public static func cellHeightForCellWidth(_ width: CGFloat) -> CGFloat {
            let imageHeight = (width - cellImageInset) * cellImageRatio
            return imageHeight + cellInfoBarHeight
        }

        public static func cellSizeForFrameWidth(_ width: CGFloat) -> CGSize {
            let cellWidth = cellWidthForFrameWidth(width)
            let cellHeight = cellHeightForCellWidth(cellWidth)
            return CGSize(width: cellWidth.zeroIfNaN(), height: cellHeight.zeroIfNaN())
        }

        public static func imageWidthForFrameWidth(_ width: CGFloat) -> CGFloat {
            let cellWidth = cellWidthForFrameWidth(width)
            return cellWidth - cellImageInset
        }

        public static let footerHeight: CGFloat = 50

        public static let themeMargins = UIEdgeInsets(top: rowMargin, left: columnMargin, bottom: rowMargin, right: columnMargin)
        public static let infoMargins = UIEdgeInsets()
    }

}
