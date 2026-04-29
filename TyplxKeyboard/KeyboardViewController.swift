import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<QWERTYKeyboardView>?
    private var isProcessing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
    }

    private func setupKeyboardView() {
        let keyboardView = QWERTYKeyboardView(
            onKeyPress: { [weak self] key in self?.insert(key) },
            onDelete: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            onReturn: { [weak self] in self?.textDocumentProxy.insertText("\n") },
            onNextKeyboard: { [weak self] in self?.advanceToNextInputMode() },
            onFixGrammar: { [weak self] in self?.fixGrammar() }
        )

        let hc = UIHostingController(rootView: keyboardView)
        hostingController = hc
        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func insert(_ key: String) {
        textDocumentProxy.insertText(key)
    }

    private func fixGrammar() {
        guard !isProcessing else { return }

        let text = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let settings = SharedSettings.shared
        guard !settings.apiURL.isEmpty, !settings.model.isEmpty, !settings.apiToken.isEmpty else { return }

        isProcessing = true
        Task {
            do {
                let corrected = try await APIService.shared.fixGrammar(text: text)
                await MainActor.run {
                    let chars = text.utf16.count
                    for _ in 0..<chars { self.textDocumentProxy.deleteBackward() }
                    self.textDocumentProxy.insertText(corrected)
                }
            } catch {
                // Best-effort: silently ignore API failures
            }
            await MainActor.run { self.isProcessing = false }
        }
    }
}
