import UIKit

protocol GrammarToolbarDelegate: AnyObject {
    func grammarToolbarDidTapFix(_ toolbar: GrammarToolbar)
}

final class GrammarToolbar: UIView {
    weak var delegate: GrammarToolbarDelegate?

    private let fixButton = UIButton(type: .system)
    private let previewLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.systemGroupedBackground
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor

        // Fix button
        var config = UIButton.Configuration.filled()
        config.title = "Fix Grammar"
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        fixButton.configuration = config
        fixButton.addTarget(self, action: #selector(fixTapped), for: .touchUpInside)

        // Preview label
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 1
        previewLabel.text = ""

        // Activity indicator
        activityIndicator.hidesWhenStopped = true

        let hStack = UIStackView(arrangedSubviews: [fixButton, previewLabel, activityIndicator])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func fixTapped() {
        delegate?.grammarToolbarDidTapFix(self)
    }

    // MARK: - State

    func showLoading() {
        fixButton.isEnabled = false
        previewLabel.text = ""
        activityIndicator.startAnimating()
    }

    func showPreview(_ text: String) {
        activityIndicator.stopAnimating()
        previewLabel.text = text.isEmpty ? "" : "→ \(text.prefix(40))\(text.count > 40 ? "…" : "")"
        fixButton.isEnabled = true
    }

    func showError(_ message: String) {
        activityIndicator.stopAnimating()
        previewLabel.text = message
        previewLabel.textColor = .systemRed
        fixButton.isEnabled = true
    }

    func reset() {
        activityIndicator.stopAnimating()
        previewLabel.text = ""
        previewLabel.textColor = .secondaryLabel
        fixButton.isEnabled = true
    }
}
