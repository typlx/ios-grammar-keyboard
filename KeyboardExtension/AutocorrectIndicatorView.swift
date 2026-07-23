import UIKit

final class AutocorrectIndicatorView: UIView {
    var onTap: (() -> Void)?

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        layer.cornerRadius = 8
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.systemOrange.cgColor

        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemOrange
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        accessibilityIdentifier = "autocorrectIndicator"
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "Tap to undo autocorrection"
    }

    func configure(original: String, corrected: String) {
        label.text = "\(original) → \(corrected)"
        accessibilityLabel = "Autocorrected \(original) to \(corrected). Tap to undo."
    }

    @objc private func handleTap() {
        onTap?()
    }
}
