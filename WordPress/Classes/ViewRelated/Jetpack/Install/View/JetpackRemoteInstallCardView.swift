import UIKit

class JetpackRemoteInstallCardView: UIView {

    // MARK: Properties

    @objc static var shouldShowJetpackInstallCard: Bool {
        // TODO: Display logic for showing/hiding the card
        // TODO: iPad display logic. Currently displays in both menu and dashboard
        return false
    }

    private let viewModel: JetpackRemoteInstallCardViewModel

    private lazy var warningImageView: UIImageView = {
        let imageView = UIImageView(image: Constants.warningIconImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addConstraints(imageConstraints(for: imageView))
        return imageView
    }()

    private lazy var jetpackImageView: UIImageView = {
        let imageView = UIImageView(image: Constants.jetpackIconImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addConstraints(imageConstraints(for: imageView))
        return imageView
    }()

    private lazy var imageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [warningImageView, jetpackImageView, UIView()])
        stackView.spacing = Constants.iconSpacing
        return stackView
    }()

    private lazy var noticeLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.noticeLabelFont
        label.attributedText = viewModel.noticeLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.learnMore, for: .normal)
        button.setTitleColor(.primary, for: .normal)
        button.titleLabel?.font = Constants.learnMoreFont
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onLearnMoreTap), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageStackView, noticeLabel, learnMoreButton])
        stackView.axis = .vertical
        stackView.spacing = Constants.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.contentDirectionalLayoutMargins
        return stackView
    }()

    private lazy var contextMenu: UIMenu = {
        let hideThisAction = UIAction(title: Strings.hideThis,
                                      image: Constants.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive]) { _ in
            // TODO: Showing/hiding the card
        }
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.icon = .none
        frameView.onEllipsisButtonTap = {}
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.add(subview: contentStackView)
        return frameView
    }()

    // MARK: Initializers

    init(_ viewModel: JetpackRemoteInstallCardViewModel = JetpackRemoteInstallCardViewModel()) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    @objc func onLearnMoreTap() {
        viewModel.onLearnMoreTap()
    }

    private func setupView() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)
    }

    private func imageConstraints(for imageView: UIImageView) -> [NSLayoutConstraint] {
        return [
            imageView.widthAnchor.constraint(equalToConstant: Constants.iconWidth),
            imageView.heightAnchor.constraint(equalToConstant: Constants.iconHeight)
        ]
    }

    // MARK: Constants

    struct Constants {
        static let warningIconImage = UIImage(named: "jetpack-install-warning")
        static let jetpackIconImage = UIImage(named: "jetpack-install-icon")
        static let hideThisImage = UIImage(systemName: "eye.slash")
        static let iconHeight: CGFloat = 30.0
        static let iconWidth: CGFloat = 30.0
        static let iconSpacing: CGFloat = -6.0
        static let contentSpacing: CGFloat = 10.0
        static let noticeLabelFont = WPStyleGuide.fontForTextStyle(.callout)
        static let learnMoreFont = WPStyleGuide.fontForTextStyle(.callout).semibold()
        static let contentDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: -24.0, leading: 20.0, bottom: 12.0, trailing: 20.0)
    }

    struct Strings {
        static let learnMore = NSLocalizedString("jetpackinstallcard.button.learn",
                                                 value: "Learn more",
                                                 comment: "Title for a call-to-action button on the Jetpack install card.")
        static let hideThis = NSLocalizedString("jetpackinstallcard.menu.hide",
                                                 value: "Hide this",
                                                 comment: "Title for a menu action in the context menu on the Jetpack install card.")

    }

}

// MARK: - JetpackRemoteInstallCardViewModel

struct JetpackRemoteInstallCardViewModel {

    let onLearnMoreTap: () -> Void
    var noticeLabel: NSAttributedString {
        switch installedPlugin {
        case .multiple:
            return NSAttributedString(string: Strings.multiplePlugins)
        default:
            let noticeText = String(format: Strings.individualPluginFormat, installedPlugin.rawValue)
            let boldNoticeText = NSMutableAttributedString(string: noticeText)
            guard let range = noticeText.nsRange(of: installedPlugin.rawValue) else {
                return boldNoticeText
            }
            boldNoticeText.addAttributes([.font: WPStyleGuide.fontForTextStyle(.callout, fontWeight: .bold)], range: range)
            return boldNoticeText
        }
    }

    private let installedPlugin: JetpackPlugin

    init(onLearnMoreTap: @escaping () -> Void = {},
         installedPlugin: JetpackPlugin = .multiple) {
        self.onLearnMoreTap = onLearnMoreTap
        self.installedPlugin = installedPlugin
    }

    enum JetpackPlugin: String {
        case search     = "Jetpack Search"
        case backup     = "Jetpack Backup"
        case protect    = "Jetpack Protect"
        case videoPress = "Jetpack VideoPress"
        case social     = "Jetpack Social"
        case boost      = "Jetpack Boost"
        case multiple
    }

    // MARK: Constants

    private struct Strings {
        static let individualPluginFormat = NSLocalizedString("jetpackinstallcard.notice.individual",
                                                              value: "This site is using the %1$@ plugin, which doesn't support all features of the app yet. Please install the full Jetpack plugin.",
                                                              comment: "Text displayed in the Jetpack install card on the Home screen and Menu screen when a user has an individual Jetpack plugin installed but not the full plugin. %1$@ is a placeholder for the plugin the user has installed. %1$@ is bold.")
        static let multiplePlugins = NSLocalizedString("jetpackinstallcard.notice.multiple",
                                                       value: "This site is using individual Jetpack plugins, which don’t support all features of the app yet. Please install the full Jetpack plugin.",
                                                       comment: "Text displayed in the Jetpack install card on the Home screen and Menu screen when a user has multiple installed individual Jetpack plugins but not the full plugin.")
    }

}
