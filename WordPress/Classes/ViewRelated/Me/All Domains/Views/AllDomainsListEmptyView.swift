import UIKit
import WordPressUI

final class AllDomainsListEmptyView: UIView {

    struct ViewModel {
        let title: String
        let description: String
        let buttonTitle: String
    }

    private enum Appearance {
        static let labelsSpacing: CGFloat = Length.Padding.single
        static let labelsButtonSpacing: CGFloat = Length.Padding.medium
        static let titleLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
        static let descriptionLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        static let buttonLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
    }

    // MARK: - Views

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Appearance.titleLabelFont
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Appearance.descriptionLabelFont
        return label
    }()

    private let button: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.titleLabel?.font = Appearance.buttonLabelFont
        return button
    }()

    // MARK: - Init

    init(viewModel: ViewModel? = nil) {
        super.init(frame: .zero)
        self.render(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rendering

    private func render(with viewModel: ViewModel?) {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, button])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Appearance.labelsSpacing
        stackView.setCustomSpacing(Appearance.labelsButtonSpacing, after: descriptionLabel)
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView)
        self.update(with: viewModel)
    }

    func update(with viewModel: ViewModel?) {
        self.titleLabel.text = viewModel?.title
        self.descriptionLabel.text = viewModel?.description
        self.button.setTitle(viewModel?.buttonTitle, for: .normal)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    let viewModel = AllDomainsListEmptyView.ViewModel(
        title: "You don't have any domains",
        description: "Tap the button below to add a new one",
        buttonTitle: "Find a domain"
    )
    return AllDomainsListEmptyView(viewModel: viewModel)
}
