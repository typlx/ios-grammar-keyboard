import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private let viewModel = KeyboardViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
    }

    private func setupKeyboardView() {
        let keyboardView = QWERTYKeyboardView(
            onKeyPress: { [weak self] key in self?.textDocumentProxy.insertText(key) },
            onDelete: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            onReturn: { [weak self] in self?.textDocumentProxy.insertText("\n") },
            onNextKeyboard: { [weak self] in self?.advanceToNextInputMode() },
            onFixGrammar: { [weak self] in self?.fixGrammar() },
            viewModel: viewModel
        )

        let hc = UIHostingController(rootView: keyboardView)
        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func fixGrammar() {
        guard !viewModel.isFixing else { return }

        let text = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("No text to fix.")
            return
        }

        let settings = SharedSettings.shared
        guard !settings.apiURL.isEmpty, !settings.model.isEmpty, !settings.apiToken.isEmpty else {
            showError("Configure API settings in the Typlx app first.")
            return
        }

        viewModel.isFixing = true
        viewModel.errorMessage = nil

        Task {
            do {
                let corrected = try await APIService.shared.fixGrammar(text: text)
                await MainActor.run {
                    let charCount = text.utf16.count
                    for _ in 0..<charCount { self.textDocumentProxy.deleteBackward() }
                    self.textDocumentProxy.insertText(corrected)
                    self.viewModel.isFixing = false
                }
            } catch {
                await MainActor.run {
                    self.viewModel.isFixing = false
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        viewModel.errorMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.viewModel.errorMessage = nil
        }
    }
}
