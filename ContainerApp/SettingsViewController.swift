import UIKit

final class SettingsViewController: UITableViewController {

    private enum Section: Int, CaseIterable {
        case provider, apiKey, model, apiURL, context
    }

    private var selectedProvider: ProviderType = .openAI
    private var openAIKey = ""
    private var anthropicKey = ""
    private var openAIModel = ""
    private var anthropicModel = ""
    private var openAIURL = ""
    private var anthropicURL = ""
    private var selectedContext: ContextType = .general

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        loadSettings()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(save)
        )
        tableView.keyboardDismissMode = .onDrag
    }

    private func loadSettings() {
        let defaults = AppGroupConfig.sharedDefaults
        let providerRaw = defaults.string(forKey: AppGroupConfig.DefaultsKey.selectedProvider.rawValue) ?? ProviderType.openAI.rawValue
        selectedProvider = ProviderType(rawValue: providerRaw) ?? .openAI
        openAIKey = (try? KeychainManager.shared.loadAPIKey(slot: .openAI)) ?? ""
        anthropicKey = (try? KeychainManager.shared.loadAPIKey(slot: .anthropic)) ?? ""
        openAIModel = defaults.string(forKey: AppGroupConfig.DefaultsKey.openAIModel.rawValue) ?? ProviderConfig.defaultOpenAI.model
        anthropicModel = defaults.string(forKey: AppGroupConfig.DefaultsKey.anthropicModel.rawValue) ?? ProviderConfig.defaultAnthropic.model
        openAIURL = defaults.string(forKey: AppGroupConfig.DefaultsKey.openAIURL.rawValue) ?? ProviderConfig.defaultOpenAI.apiURL
        anthropicURL = defaults.string(forKey: AppGroupConfig.DefaultsKey.anthropicURL.rawValue) ?? ProviderConfig.defaultAnthropic.apiURL
        let contextRaw = defaults.string(forKey: AppGroupConfig.DefaultsKey.defaultContext.rawValue) ?? ContextType.general.rawValue
        selectedContext = ContextType(rawValue: contextRaw) ?? .general
    }

    @objc private func save() {
        let defaults = AppGroupConfig.sharedDefaults
        defaults.set(selectedProvider.rawValue, forKey: AppGroupConfig.DefaultsKey.selectedProvider.rawValue)
        defaults.set(openAIModel, forKey: AppGroupConfig.DefaultsKey.openAIModel.rawValue)
        defaults.set(anthropicModel, forKey: AppGroupConfig.DefaultsKey.anthropicModel.rawValue)
        defaults.set(openAIURL, forKey: AppGroupConfig.DefaultsKey.openAIURL.rawValue)
        defaults.set(anthropicURL, forKey: AppGroupConfig.DefaultsKey.anthropicURL.rawValue)
        defaults.set(selectedContext.rawValue, forKey: AppGroupConfig.DefaultsKey.defaultContext.rawValue)

        do {
            if !openAIKey.isEmpty { try KeychainManager.shared.saveAPIKey(openAIKey, slot: .openAI) }
            if !anthropicKey.isEmpty { try KeychainManager.shared.saveAPIKey(anthropicKey, slot: .anthropic) }
        } catch {
            showAlert(title: "Keychain Error", message: error.localizedDescription)
            return
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .provider: return ProviderType.allCases.count
        case .apiKey: return 2
        case .model: return 2
        case .apiURL: return 2
        case .context: return ContextType.allCases.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .provider: return "Provider"
        case .apiKey: return "API Keys (stored in Keychain)"
        case .model: return "Models"
        case .apiURL: return "API URLs"
        case .context: return "Default Context"
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .provider:
            let type = ProviderType.allCases[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: "provider")
            cell.textLabel?.text = type.rawValue.capitalized
            cell.accessoryType = type == selectedProvider ? .checkmark : .none
            return cell

        case .apiKey:
            let cell = textFieldCell(
                label: indexPath.row == 0 ? "OpenAI Key" : "Anthropic Key",
                value: indexPath.row == 0 ? openAIKey : anthropicKey,
                placeholder: "sk-...",
                secure: true
            ) { [weak self] text in
                if indexPath.row == 0 { self?.openAIKey = text } else { self?.anthropicKey = text }
            }
            return cell

        case .model:
            let cell = textFieldCell(
                label: indexPath.row == 0 ? "OpenAI Model" : "Anthropic Model",
                value: indexPath.row == 0 ? openAIModel : anthropicModel,
                placeholder: indexPath.row == 0 ? "gpt-4o-mini" : "claude-haiku-4-5-20251001",
                secure: false
            ) { [weak self] text in
                if indexPath.row == 0 { self?.openAIModel = text } else { self?.anthropicModel = text }
            }
            return cell

        case .apiURL:
            let cell = textFieldCell(
                label: indexPath.row == 0 ? "OpenAI URL" : "Anthropic URL",
                value: indexPath.row == 0 ? openAIURL : anthropicURL,
                placeholder: indexPath.row == 0 ? ProviderConfig.defaultOpenAI.apiURL : ProviderConfig.defaultAnthropic.apiURL,
                secure: false
            ) { [weak self] text in
                if indexPath.row == 0 { self?.openAIURL = text } else { self?.anthropicURL = text }
            }
            return cell

        case .context:
            let ctx = ContextType.allCases[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: "context")
            cell.textLabel?.text = ctx.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
            cell.accessoryType = ctx == selectedContext ? .checkmark : .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .provider:
            selectedProvider = ProviderType.allCases[indexPath.row]
            tableView.reloadSections([Section.provider.rawValue], with: .none)
        case .context:
            selectedContext = ContextType.allCases[indexPath.row]
            tableView.reloadSections([Section.context.rawValue], with: .none)
        default: break
        }
    }

    // MARK: - Helpers

    private func textFieldCell(
        label: String,
        value: String,
        placeholder: String,
        secure: Bool,
        onChange: @escaping (String) -> Void
    ) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = label
        let tf = UITextField(frame: .zero)
        tf.text = value
        tf.placeholder = placeholder
        tf.isSecureTextEntry = secure
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(tf)
        NSLayoutConstraint.activate([
            tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            tf.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            tf.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.5)
        ])
        tf.addAction(UIAction { _ in onChange(tf.text ?? "") }, for: .editingChanged)
        return cell
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
