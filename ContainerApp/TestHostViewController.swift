import UIKit

/// Embedded test host shown when the app is launched with `--uitesting`.
/// Provides a regular text field, a secure text field, and a GrammarToolbar
/// so XCUITests can exercise keyboard-extension UI without requiring the
/// custom keyboard to be registered in the simulator's Settings.
final class TestHostViewController: UIViewController {

    private let grammarToolbar = GrammarToolbar()
    private let regularTextField = UITextField()
    private let secureTextField = UITextField()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Keyboard Test Host"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        grammarToolbar.delegate = self
        grammarToolbar.translatesAutoresizingMaskIntoConstraints = false

        regularTextField.placeholder = "Type here to test grammar check"
        regularTextField.borderStyle = .roundedRect
        regularTextField.accessibilityIdentifier = "testRegularTextField"
        regularTextField.autocorrectionType = .no
        regularTextField.translatesAutoresizingMaskIntoConstraints = false

        secureTextField.placeholder = "Password field (grammar disabled)"
        secureTextField.borderStyle = .roundedRect
        secureTextField.isSecureTextEntry = true
        secureTextField.accessibilityIdentifier = "testSecureTextField"
        secureTextField.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.text = "Idle"
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.accessibilityIdentifier = "testStatusLabel"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [grammarToolbar, regularTextField, secureTextField, statusLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            grammarToolbar.heightAnchor.constraint(equalToConstant: 44),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        regularTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        grammarToolbar.isSecureEntryActive = false
        statusLabel.text = "Typing in regular field"
    }
}

extension TestHostViewController: GrammarToolbarDelegate {
    func grammarToolbarDidTapFix(_ toolbar: GrammarToolbar) {
        let text = regularTextField.text ?? ""
        guard !text.isEmpty else {
            toolbar.showError("No text to correct.")
            statusLabel.text = "Error: no text"
            return
        }
        toolbar.showLoading()
        statusLabel.text = "Checking grammar…"

        // Simulate async grammar check with local provider so tests don't need network.
        Task {
            let request = GrammarRequest(text: text, context: .general, language: .english)
            let provider = LocalGrammarProvider()
            do {
                let response = try await provider.correct(request)
                await MainActor.run {
                    toolbar.showPreview(response.correctedText)
                    self.statusLabel.text = "Suggestion ready"
                }
            } catch {
                await MainActor.run {
                    toolbar.showError("Correction unavailable.")
                    self.statusLabel.text = "Error: correction failed"
                }
            }
        }
    }
}
