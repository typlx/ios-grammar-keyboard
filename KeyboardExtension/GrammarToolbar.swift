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

    // MARK: - State transitions

    func showLoading() {
        fixButton.isEnabled = false
        activityIndicator.startAnimating()
        animateLabel(text: "", color: .secondaryLabel)
    }

    func showPreview(_ text: String) {
        activityIndicator.stopAnimating()
        fixButton.isEnabled = true
        let truncated = text.isEmpty ? "" : "→ \(text.prefix(40))\(text.count > 40 ? "…" : "")"
        animateLabel(text: truncated, color: .secondaryLabel)
    }

    func showError(_ message: String) {
        activityIndicator.stopAnimating()
        fixButton.isEnabled = true
        animateLabel(text: message, color: .systemRed)
    }

    func reset() {
        activityIndicator.stopAnimating()
        fixButton.isEnabled = true
        animateLabel(text: "", color: .secondaryLabel)
    }

    // Crossfade the preview label so state changes feel smooth.
    private func animateLabel(text: String, color: UIColor) {
        UIView.transition(with: previewLabel, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.previewLabel.text = text
            self.previewLabel.textColor = color
        }
    }
}
