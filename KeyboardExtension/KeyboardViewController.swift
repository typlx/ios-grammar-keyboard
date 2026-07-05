import UIKit

final class KeyboardViewController: UIInputViewController {

    private let grammarToolbar = GrammarToolbar()
    private var toolbarHeightConstraint: NSLayoutConstraint!
    private var keyboardView: UIView?
    private var currentProvider: (any GrammarProvider)?
    private var pendingCorrectedText: String?
    private var lastSeenText: String = ""

    private let keyImpact = UIImpactFeedbackGenerator(style: .light)
    private let correctionImpact = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Keyboard background and key colors (dark-mode adaptive)

    private static let keyboardBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.17, alpha: 1)
            : UIColor(white: 0.82, alpha: 1)
    }

    private static let keyBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.37, alpha: 1)
            : UIColor.white
    }

    private static let specialKeyBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.27, alpha: 1)
            : UIColor(white: 0.68, alpha: 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        keyImpact.prepare()
        correctionImpact.prepare()
        configureProvider()
        setupToolbar()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureProvider()
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        grammarToolbar.isSecureEntryActive = textDocumentProxy.isSecureTextEntry
    }

    // MARK: - Provider

    private func configureProvider() {
        let config = AppGroupConfig.activeProviderConfig()
        currentProvider = ProviderRegistry.shared.makeProvider(config: config)

        // Show/hide grammar toolbar based on the autocorrect setting (default: enabled).
        let enabled = AppGroupConfig.bool(for: .autocorrectEnabled, defaultValue: true)
        grammarToolbar.isHidden = !enabled
        toolbarHeightConstraint?.constant = enabled ? 44 : 0

        grammarToolbar.isSecureEntryActive = textDocumentProxy.isSecureTextEntry
    }

    // MARK: - Layout

    private func setupToolbar() {
        grammarToolbar.delegate = self
        grammarToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grammarToolbar)
        toolbarHeightConstraint = grammarToolbar.heightAnchor.constraint(equalToConstant: 44)
        NSLayoutConstraint.activate([
            grammarToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            grammarToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            grammarToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarHeightConstraint
        ])
    }

    private func setupKeyboard() {
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
        container.backgroundColor = Self.keyboardBackground

        // Use a vertical stack with fillEqually so rows adapt to any keyboard height.
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.distribution = .fillEqually
        outerStack.spacing = 4
        outerStack.layoutMargins = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        outerStack.isLayoutMarginsRelativeArrangement = true
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        for row in rows {
            outerStack.addArrangedSubview(buildKeyRow(keys: row))
        }
        outerStack.addArrangedSubview(buildBottomRow())

        container.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: container.topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func buildKeyRow(keys: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        for key in keys {
            let btn = makeKeyButton(title: key, isSpecial: false)
            btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            btn.accessibilityLabel = key
            stack.addArrangedSubview(btn)
        }
        return stack
    }

    private func buildBottomRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4

        let spaceBtn = makeKeyButton(title: "space", isSpecial: false)
        spaceBtn.tag = 1
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)

        let deleteBtn = makeKeyButton(title: "⌫", isSpecial: true)
        deleteBtn.tag = 2
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let returnBtn = makeKeyButton(title: "return", isSpecial: true)
        returnBtn.tag = 3
        returnBtn.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)

        stack.addArrangedSubview(deleteBtn)
        stack.addArrangedSubview(spaceBtn)
        stack.addArrangedSubview(returnBtn)

        deleteBtn.widthAnchor.constraint(equalTo: spaceBtn.widthAnchor, multiplier: 0.5).isActive = true
        returnBtn.widthAnchor.constraint(equalTo: spaceBtn.widthAnchor, multiplier: 0.7).isActive = true

        return stack
    }

    private func makeKeyButton(title: String, isSpecial: Bool) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = isSpecial ? Self.specialKeyBackground : Self.keyBackground
        btn.setTitleColor(.label, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.layer.cornerRadius = 5
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 0
        return btn
    }

    // MARK: - Key actions

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        triggerKeyHaptic()
        textDocumentProxy.insertText(title)
        pendingCorrectedText = nil
        grammarToolbar.reset()
    }

    @objc private func spaceTapped() {
        triggerKeyHaptic()
        textDocumentProxy.insertText(" ")
        pendingCorrectedText = nil
        grammarToolbar.reset()
    }

    @objc private func deleteTapped() {
        triggerKeyHaptic()
        textDocumentProxy.deleteBackward()
        pendingCorrectedText = nil
        grammarToolbar.reset()
    }

    @objc private func returnTapped() {
        triggerKeyHaptic()
        textDocumentProxy.insertText("\n")
        pendingCorrectedText = nil
        grammarToolbar.reset()
    }

    private func triggerKeyHaptic() {
        guard AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true) else { return }
        keyImpact.impactOccurred()
    }

    // MARK: - Text Document Proxy Helpers

    private func extractCurrentSentence() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let full = before + after
        if let range = before.range(of: ".", options: .backwards) {
            let start = before.index(after: range.lowerBound)
            return String(before[start...] + after).trimmingCharacters(in: .whitespaces)
        }
        return full.trimmingCharacters(in: .whitespaces)
    }

    private func replaceCurrentSentence(with corrected: String) {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""

        if !after.isEmpty {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: after.count)
        }
        let totalChars = before.count + after.count
        for _ in 0..<totalChars {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(corrected)
    }
}

// MARK: - GrammarToolbarDelegate

extension KeyboardViewController: GrammarToolbarDelegate {
    func grammarToolbarDidTapFix(_ toolbar: GrammarToolbar) {
        guard !textDocumentProxy.isSecureTextEntry else {
            toolbar.showError("Grammar check is disabled in password fields.")
            return
        }
        guard hasFullAccess else {
            toolbar.showError("Enable Full Access in Settings → General → Keyboard.")
            return
        }
        guard FeatureGate.shared.isEnabled(.advancedGrammar) else {
            toolbar.showError("Upgrade to Premium to unlock advanced grammar correction.")
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
            if AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true) {
                correctionImpact.impactOccurred()
            }
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
                let languageRaw = AppGroupConfig.string(for: .language) ?? CorrectionLanguage.english.rawValue
                let language = CorrectionLanguage(rawValue: languageRaw) ?? .english
                let request = GrammarRequest(text: text, context: context, language: language)
                let response = try await provider.correct(request)
                await MainActor.run {
                    pendingCorrectedText = response.correctedText
                    toolbar.showPreview(response.correctedText)
                }
            } catch let error as GrammarProviderError {
                await MainActor.run {
                    toolbar.showError(gracefulMessage(for: error))
                }
            } catch {
                await MainActor.run {
                    toolbar.showError("Correction unavailable. Try again later.")
                }
            }
        }
    }

    private func gracefulMessage(for error: GrammarProviderError) -> String {
        error.gracefulKeyboardMessage
    }
}
