import UIKit

final class KeyboardViewController: UIInputViewController {

    private let grammarToolbar = GrammarToolbar()
    private var keyboardView: UIView?
    private var currentProvider: (any GrammarProvider)?
    private var pendingCorrectedText: String?
    private var alternativesPopup: AlternativesPopupView?
    private let autocorrectMachine = AutocorrectStateMachine()
    private var keyButtons: [UIButton] = []

    // Tracks the last text seen from the proxy to detect changes.
    private var lastSeenText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        configureProvider()
        setupToolbar()
        setupKeyboard()
        autocorrectMachine.delegate = self
        grammarToolbar.onAutocorrectUndo = { [weak self] in
            self?.autocorrectMachine.undo()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureProvider()
        applyTheme()
    }

    // MARK: - Theme

    private func applyTheme() {
        let theme = ThemeManager.shared.resolvedTheme(for: traitCollection)
        keyboardView?.backgroundColor = theme.keyboardBackground
        for btn in keyButtons {
            btn.backgroundColor = theme.keyBackground
            btn.setTitleColor(theme.keyText, for: .normal)
            btn.layer.shadowColor = UIColor.black.cgColor
        }
        grammarToolbar.applyTheme(theme)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }

    // MARK: - Provider

    private func configureProvider() {
        let config = AppGroupConfig.activeProviderConfig()
        currentProvider = ProviderRegistry.shared.makeProvider(config: config)
    }

    // MARK: - Layout

    private func setupToolbar() {
        grammarToolbar.delegate = self
        grammarToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grammarToolbar)
        NSLayoutConstraint.activate([
            grammarToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            grammarToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            grammarToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            grammarToolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupKeyboard() {
        // Build a simple standard QWERTY-style keyboard using UIButtons.
        // In a production build this would be replaced with a full custom keyboard layout.
        let keyboard = buildQWERTYView()
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.topAnchor.constraint(equalTo: grammarToolbar.bottomAnchor),
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        keyboardView = keyboard
    }

    private func buildQWERTYView() -> UIView {
        let rows: [[String]] = [
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["z","x","c","v","b","n","m"],
        ]
        let container = UIView()
        container.backgroundColor = ThemeManager.shared.resolvedTheme(for: traitCollection).keyboardBackground

        var previousRow: UIView?
        for (_, row) in rows.enumerated() {
            let rowView = buildKeyRow(keys: row)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(rowView)
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
                rowView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
                rowView.heightAnchor.constraint(equalToConstant: 42)
            ])
            if let prev = previousRow {
                rowView.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 4).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4).isActive = true
            }
            previousRow = rowView
        }

        // Bottom row: space + delete + return
        let bottomRow = buildBottomRow()
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomRow)
        if let prev = previousRow {
            NSLayoutConstraint.activate([
                bottomRow.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 4),
                bottomRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
                bottomRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
                bottomRow.heightAnchor.constraint(equalToConstant: 42),
                bottomRow.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -4)
            ])
        }

        return container
    }

    private func buildKeyRow(keys: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        for key in keys {
            let btn = makeKeyButton(title: key)
            btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            btn.accessibilityLabel = key
            if !KeyAlternatives.alternatives(for: key).isEmpty {
                let longPress = UILongPressGestureRecognizer(
                    target: self,
                    action: #selector(keyLongPressed(_:))
                )
                longPress.minimumPressDuration = 0.4
                btn.addGestureRecognizer(longPress)
            }
            stack.addArrangedSubview(btn)
        }
        return stack
    }

    private func buildBottomRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4

        let spaceBtn = makeKeyButton(title: "space")
        spaceBtn.tag = 1
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)

        let deleteBtn = makeKeyButton(title: "⌫")
        deleteBtn.tag = 2
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let returnBtn = makeKeyButton(title: "return")
        returnBtn.tag = 3
        returnBtn.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)

        stack.addArrangedSubview(deleteBtn)
        stack.addArrangedSubview(spaceBtn)
        stack.addArrangedSubview(returnBtn)

        deleteBtn.widthAnchor.constraint(equalTo: spaceBtn.widthAnchor, multiplier: 0.5).isActive = true
        returnBtn.widthAnchor.constraint(equalTo: spaceBtn.widthAnchor, multiplier: 0.7).isActive = true

        return stack
    }

    private func makeKeyButton(title: String) -> UIButton {
        let theme = ThemeManager.shared.resolvedTheme(for: traitCollection)
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = theme.keyBackground
        btn.setTitleColor(theme.keyText, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.layer.cornerRadius = 5
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 0
        keyButtons.append(btn)
        return btn
    }

    // MARK: - Key actions

    @objc private func keyLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let btn = gesture.view as? UIButton,
              let key = btn.currentTitle else { return }

        let alternatives = KeyAlternatives.alternatives(for: key)
        guard !alternatives.isEmpty else { return }

        switch gesture.state {
        case .began:
            showAlternativesPopup(for: btn, alternatives: alternatives)

        case .changed:
            let location = gesture.location(in: view)
            alternativesPopup?.updateHighlight(forTouchAt: location)

        case .ended:
            if let selected = alternativesPopup?.selectedAlternative {
                textDocumentProxy.insertText(selected)
                pendingCorrectedText = nil
            }
            dismissAlternativesPopup()

        case .cancelled, .failed:
            dismissAlternativesPopup()

        default:
            break
        }
    }

    private func showAlternativesPopup(for key: UIButton, alternatives: [String]) {
        dismissAlternativesPopup()

        let popup = AlternativesPopupView(alternatives: alternatives, traitCollection: traitCollection)
        let keyFrameInView = key.convert(key.bounds, to: view)
        let popupSize = AlternativesPopupView.size(for: alternatives.count)

        let centeredX = keyFrameInView.midX - popupSize.width / 2
        let clampedX = max(4, min(view.bounds.width - popupSize.width - 4, centeredX))
        let popupY = max(0, keyFrameInView.minY - popupSize.height - 4)

        popup.frame = CGRect(origin: CGPoint(x: clampedX, y: popupY), size: popupSize)
        view.addSubview(popup)
        alternativesPopup = popup

        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut) {
            popup.alpha = 1
            popup.transform = .identity
        }
    }

    private func dismissAlternativesPopup() {
        guard let popup = alternativesPopup else { return }
        alternativesPopup = nil
        UIView.animate(withDuration: 0.1) {
            popup.alpha = 0
        } completion: { _ in
            popup.removeFromSuperview()
        }
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        textDocumentProxy.insertText(title)
    }

    @objc private func spaceTapped() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let lastWord = before.components(separatedBy: .whitespacesAndNewlines).last ?? ""

        if !lastWord.isEmpty, let correction = AutocorrectDictionary.correction(for: lastWord) {
            for _ in 0..<lastWord.count {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(correction + " ")
            autocorrectMachine.show(original: lastWord, corrected: correction)
        } else {
            textDocumentProxy.insertText(" ")
        }
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }

    // MARK: - Text Document Proxy Helpers

    private func extractCurrentSentence() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let full = before + after
        // Extract the last sentence/paragraph as the correction target.
        if let range = before.range(of: ".", options: .backwards) {
            let start = before.index(after: range.lowerBound)
            return String(before[start...] + after).trimmingCharacters(in: .whitespaces)
        }
        return full.trimmingCharacters(in: .whitespaces)
    }

    private func replaceCurrentSentence(with corrected: String) {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""

        // Move to end of current sentence.
        if !after.isEmpty {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: after.count)
        }
        // Delete before+after characters.
        let totalChars = before.count + after.count
        for _ in 0..<totalChars {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(corrected)
    }
}

// MARK: - AutocorrectStateMachineDelegate

extension KeyboardViewController: AutocorrectStateMachineDelegate {
    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didShow original: String, corrected: String) {
        grammarToolbar.showAutocorrectIndicator(original: original, corrected: corrected)
    }

    func autocorrectStateMachineDidDismiss(_ machine: AutocorrectStateMachine) {
        grammarToolbar.hideAutocorrectIndicator()
    }

    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didUndo original: String, corrected: String) {
        // Bail out if the cursor has moved away from the corrected word; deleting
        // blindly would corrupt text that the user typed after the correction.
        guard let before = textDocumentProxy.documentContextBeforeInput,
              before.hasSuffix(" " + corrected) else {
            return
        }
        // Replace the corrected word + trailing space with the original word.
        textDocumentProxy.deleteBackward() // remove the trailing space
        for _ in 0..<corrected.count {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(original)
    }
}

// MARK: - GrammarToolbarDelegate

extension KeyboardViewController: GrammarToolbarDelegate {
    func grammarToolbarDidTapFix(_ toolbar: GrammarToolbar) {
        guard hasFullAccess else {
            toolbar.showError("Enable Full Access in Settings → General → Keyboard.")
            return
        }
        guard let provider = currentProvider else {
            toolbar.showError("No provider configured.")
            return
        }

        if let corrected = pendingCorrectedText {
            // Second tap: apply the correction.
            replaceCurrentSentence(with: corrected)
            pendingCorrectedText = nil
            toolbar.reset()
            return
        }

        let text = extractCurrentSentence()
        guard !text.isEmpty else {
            toolbar.showError("No text to correct.")
            return
        }

        toolbar.showLoading()

        Task {
            do {
                let contextRaw = AppGroupConfig.string(for: .defaultContext) ?? ContextType.general.rawValue
                let context = ContextType(rawValue: contextRaw) ?? .general
                let response = try await provider.correct(GrammarRequest(text: text, context: context))
                await MainActor.run {
                    pendingCorrectedText = response.correctedText
                    toolbar.showPreview(response.correctedText)
                }
            } catch {
                await MainActor.run {
                    toolbar.showError(error.localizedDescription)
                }
            }
        }
    }
}
