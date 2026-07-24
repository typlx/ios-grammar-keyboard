import UIKit

protocol SuggestionBarDelegate: AnyObject {
    func suggestionBar(_ bar: SuggestionBar, didSelect word: String)
    func suggestionBar(_ bar: SuggestionBar, didSelectEmoji emoji: String)
}

extension SuggestionBarDelegate {
    func suggestionBar(_ bar: SuggestionBar, didSelectEmoji emoji: String) {}
}

/// Horizontal strip displayed between the grammar toolbar and the keyboard rows.
/// Shows up to 3 tappable word-suggestion pills on the left; when the current
/// word has emoji matches they appear at the trailing edge (larger, no pill).
final class SuggestionBar: UIView {

    weak var delegate: SuggestionBarDelegate?

    // Stored as a named property so Mirror can find it by label in tests.
    private(set) var buttons: [UIButton] = []
    private(set) var emojiButtons: [UIButton] = []

    private var emojiSeparator: UIView!
    private var emojiStack: UIStackView!

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

        let outerStack = UIStackView()
        outerStack.axis = .horizontal
        outerStack.distribution = .fill
        outerStack.alignment = .fill
        outerStack.spacing = 0
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Word suggestions — fills all available space
        let wordStack = UIStackView()
        wordStack.axis = .horizontal
        wordStack.distribution = .fillEqually
        wordStack.spacing = 1
        wordStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        outerStack.addArrangedSubview(wordStack)

        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.accessibilityIdentifier = "suggestionButton\(i)"
            btn.isEnabled = false
            btn.titleLabel?.font = i == 1
                ? .boldSystemFont(ofSize: 15)   // middle = primary pick
                : .systemFont(ofSize: 15)
            btn.setTitleColor(.label, for: .normal)
            btn.setTitleColor(.tertiaryLabel, for: .disabled)
            btn.tag = i
            btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            wordStack.addArrangedSubview(btn)
            buttons.append(btn)
        }

        // Thin separator — hidden until emoji section becomes visible
        emojiSeparator = UIView()
        emojiSeparator.backgroundColor = UIColor.separator
        emojiSeparator.isHidden = true
        outerStack.addArrangedSubview(emojiSeparator)
        emojiSeparator.widthAnchor.constraint(equalToConstant: 0.5).isActive = true

        // Emoji suggestions — hidden until updateEmoji receives a non-empty list
        emojiStack = UIStackView()
        emojiStack.axis = .horizontal
        emojiStack.distribution = .fillEqually
        emojiStack.spacing = 0
        emojiStack.isHidden = true
        outerStack.addArrangedSubview(emojiStack)

        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.accessibilityIdentifier = "emojiButton\(i)"
            btn.isEnabled = false
            btn.titleLabel?.font = .systemFont(ofSize: 20)  // slightly larger than word pills
            btn.setTitleColor(.label, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(emojiButtonTapped(_:)), for: .touchUpInside)
            btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            emojiStack.addArrangedSubview(btn)
            emojiButtons.append(btn)
        }

        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
    }

    // MARK: - Public API

    /// Update the word-prediction pills. Pass an empty array to clear all.
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

    /// Update the trailing emoji section. Pass an empty array to hide it.
    func updateEmoji(emojis: [String]) {
        let hasEmoji = !emojis.isEmpty
        emojiSeparator.isHidden = !hasEmoji
        emojiStack.isHidden = !hasEmoji

        for i in 0..<3 {
            if i < emojis.count {
                emojiButtons[i].setTitle(emojis[i], for: .normal)
                emojiButtons[i].isEnabled = true
            } else {
                emojiButtons[i].setTitle(nil, for: .normal)
                emojiButtons[i].isEnabled = false
            }
        }
    }

    // MARK: - Theme

    func applyTheme(_ theme: KeyboardTheme) {
        backgroundColor = theme.toolbarBackground
        for btn in buttons {
            btn.setTitleColor(theme.keyText, for: .normal)
        }
        for btn in emojiButtons {
            btn.setTitleColor(theme.keyText, for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.isEnabled, let word = sender.title(for: .normal) else { return }
        delegate?.suggestionBar(self, didSelect: word)
    }

    @objc private func emojiButtonTapped(_ sender: UIButton) {
        guard sender.isEnabled, let emoji = sender.title(for: .normal) else { return }
        delegate?.suggestionBar(self, didSelectEmoji: emoji)
    }
}
