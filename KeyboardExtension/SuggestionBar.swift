import UIKit

protocol SuggestionBarDelegate: AnyObject {
    func suggestionBar(_ bar: SuggestionBar, didSelect word: String)
}

/// Horizontal strip of up to 3 tappable word-suggestion pills displayed
/// between the grammar toolbar and the keyboard rows.
final class SuggestionBar: UIView {

    weak var delegate: SuggestionBarDelegate?

    // Stored as a named property so Mirror can find it by label.
    private(set) var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor.systemGroupedBackground

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.accessibilityIdentifier = "suggestionButton\(i)"
            btn.isEnabled = false
            btn.titleLabel?.font = i == 1
                ? .boldSystemFont(ofSize: 15)  // middle = primary pick
                : .systemFont(ofSize: 15)
            btn.setTitleColor(.label, for: .normal)
            btn.setTitleColor(.tertiaryLabel, for: .disabled)
            btn.tag = i
            btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
            buttons.append(btn)
        }

        // Thin vertical separators between buttons
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
    }

    // MARK: - Public API

    /// Update displayed suggestions. Pass an empty array to clear all buttons.
    func update(suggestions: [String]) {
        for i in 0..<3 {
            if i < suggestions.count {
                buttons[i].setTitle(suggestions[i], for: .normal)
                buttons[i].isEnabled = true
            } else {
                buttons[i].setTitle(nil, for: .normal)
                buttons[i].isEnabled = false
            }
        }
    }

    // MARK: - Theme

    func applyTheme(_ theme: KeyboardTheme) {
        backgroundColor = theme.toolbarBackground
        for btn in buttons {
            btn.setTitleColor(theme.keyText, for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.isEnabled, let word = sender.title(for: .normal) else { return }
        delegate?.suggestionBar(self, didSelect: word)
    }
}
