import UIKit

final class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Typist"
        view.backgroundColor = .systemBackground
        setupUI()
        checkFullAccessStatus()
    }

    private func setupUI() {
        let settingsBtn = UIButton(type: .system)
        settingsBtn.setTitle("Open Settings", for: .normal)
        settingsBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        settingsBtn.accessibilityIdentifier = "openSettingsButton"
        settingsBtn.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [makeHeroLabel(), makeSubtitleLabel(), settingsBtn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
    }

    private func makeHeroLabel() -> UILabel {
        let label = UILabel()
        label.text = "Typist"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.accessibilityIdentifier = "mainTitleLabel"
        return label
    }

    private func makeSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.text = "AI-powered grammar correction keyboard"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }

    private func checkFullAccessStatus() {
        // On iOS 16+ we can show a prompt if Full Access is not yet enabled.
        guard #available(iOS 16, *) else { return }
        // The main app itself cannot detect keyboard Full Access status directly;
        // we just show onboarding on first launch.
        let defaults = AppGroupConfig.sharedDefaults
        if !defaults.bool(forKey: "onboardingShown") {
            defaults.set(true, forKey: "onboardingShown")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.presentOnboarding()
            }
        }
    }

    private func presentOnboarding() {
        let vc = OnboardingViewController()
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }
}
