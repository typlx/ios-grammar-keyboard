import UIKit

final class OnboardingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Enable Typist Keyboard"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center

        let steps: [(String, String)] = [
            ("1. Add the keyboard",
             "Go to Settings → General → Keyboard → Keyboards → Add New Keyboard → Typist Keyboard."),
            ("2. Enable Full Access",
             "Tap Typist Keyboard, then turn on Allow Full Access.\n\nFull Access is required for network calls to the grammar API. Your text is only sent when you tap the 'Fix Grammar' button and is never stored on our servers."),
            ("3. Configure your API key",
             "Tap 'Open Settings' in Typist and enter your OpenAI or Anthropic API key.")
        ]

        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 20

        for (heading, body) in steps {
            let headingLabel = UILabel()
            headingLabel.text = heading
            headingLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            headingLabel.numberOfLines = 0

            let bodyLabel = UILabel()
            bodyLabel.text = body
            bodyLabel.font = .systemFont(ofSize: 14)
            bodyLabel.textColor = .secondaryLabel
            bodyLabel.numberOfLines = 0

            let step = UIStackView(arrangedSubviews: [headingLabel, bodyLabel])
            step.axis = .vertical
            step.spacing = 4
            stepsStack.addArrangedSubview(step)
        }

        let privacyLabel = UILabel()
        privacyLabel.text = "Privacy: Text is only sent to your chosen provider when you actively tap 'Fix Grammar'. Typist never logs your text or API key."
        privacyLabel.font = .systemFont(ofSize: 12)
        privacyLabel.textColor = .tertiaryLabel
        privacyLabel.numberOfLines = 0
        privacyLabel.textAlignment = .center

        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Got it", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        doneBtn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, stepsStack, privacyLabel, doneBtn])
        mainStack.axis = .vertical
        mainStack.spacing = 28
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
