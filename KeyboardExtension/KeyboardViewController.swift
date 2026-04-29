import UIKit

/// Custom keyboard extension that provides a "Fix Grammar" button.
/// When tapped, the button reads the current text from the active text field,
/// sends it to the configured LLM API via `GrammarService`, and replaces
/// the text with the corrected version.
class KeyboardViewController: UIInputViewController {

    // MARK: - UI Elements

    private let fixButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let nextKeyboardButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - State

    private var isProcessing = false {
        didSet { updateUI() }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Ensure minimum keyboard height.
        let desiredHeight: CGFloat = 200
        if view.frame.height < desiredHeight {
            let constraint = view.heightAnchor.constraint(equalToConstant: desiredHeight)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        configurNextKeyboardButton()
        configureFixButton()
        configureStatusLabel()
        configureActivityIndicator()
        layoutComponents()
    }

    private func configurNextKeyboardButton() {
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        nextKeyboardButton.addTarget(
            self,
            action: #selector(handleInputModeList(from:with:)),
            for: .allTouchEvents
        )
        view.addSubview(nextKeyboardButton)
    }

    private func configureFixButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Fix Grammar"
        config.image = UIImage(systemName: "sparkles")
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        fixButton.configuration = config
        fixButton.translatesAutoresizingMaskIntoConstraints = false
        fixButton.addTarget(self, action: #selector(fixGrammarTapped), for: .touchUpInside)
        view.addSubview(fixButton)
    }

    private func configureStatusLabel() {
        statusLabel.text = "Tap \"Fix Grammar\" to correct the current text."
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
    }

    private func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
    }

    private func layoutComponents() {
        NSLayoutConstraint.activate([
            // Next keyboard button — bottom-left corner.
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            // Fix Grammar button — centered.
            fixButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fixButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            fixButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            fixButton.heightAnchor.constraint(equalToConstant: 50),

            // Status label — below the button.
            statusLabel.topAnchor.constraint(equalTo: fixButton.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Activity indicator — centered on the button.
            activityIndicator.centerXAnchor.constraint(equalTo: fixButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: fixButton.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func fixGrammarTapped() {
        guard !isProcessing else { return }

        guard let proxy = textDocumentProxy as? UITextDocumentProxy else { return }
        let currentText = extractFullText(from: proxy)

        guard !currentText.isEmpty else {
            showStatus("No text to fix. Type something first.", isError: true)
            return
        }

        isProcessing = true
        showStatus("Fixing grammar...", isError: false)

        Task {
            do {
                let corrected = try await GrammarService.fixGrammar(currentText)
                await MainActor.run {
                    replaceAllText(with: corrected)
                    showStatus("Grammar fixed!", isError: false)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    showStatus(error.localizedDescription, isError: true)
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - Text Proxy Helpers

    /// Reads the full contents of the text field via the document proxy.
    /// The proxy only exposes `documentContextBeforeInput` and
    /// `documentContextAfterInput`, so we concatenate both.
    private func extractFullText(from proxy: UITextDocumentProxy) -> String {
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        return before + after
    }

    /// Deletes all existing text and inserts the replacement.
    private func replaceAllText(with newText: String) {
        guard let proxy = textDocumentProxy as? UITextDocumentProxy else { return }

        // Move cursor to the end.
        if let after = proxy.documentContextAfterInput {
            proxy.adjustTextPosition(byCharacterOffset: after.count)
        }

        // Delete all text before the cursor.
        if let before = proxy.documentContextBeforeInput {
            for _ in 0..<before.count {
                proxy.deleteBackward()
            }
        }

        // Insert corrected text.
        proxy.insertText(newText)
    }

    // MARK: - UI Updates

    private func updateUI() {
        fixButton.isEnabled = !isProcessing
        fixButton.alpha = isProcessing ? 0.5 : 1.0

        if isProcessing {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func showStatus(_ message: String, isError: Bool) {
        statusLabel.text = message
        statusLabel.textColor = isError ? .systemRed : .secondaryLabel
    }
}
