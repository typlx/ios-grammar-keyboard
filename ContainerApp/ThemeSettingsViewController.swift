import UIKit

final class ThemeSettingsViewController: UITableViewController {

    private enum Section: Int, CaseIterable {
        case preset, customColors, preview
    }

    private var selectedPreset: ThemePreset = ThemeManager.shared.selectedPreset
    private var customKeyBackground: UIColor = ThemeManager.shared.customKeyBackground
    private var customKeyText: UIColor = ThemeManager.shared.customKeyText
    private var customAccent: UIColor = ThemeManager.shared.customAccent

    private var activeColorTarget: AppGroupConfig.DefaultsKey?
    private var previewView: KeyboardPreviewView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Appearance"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(save)
        )
    }

    @objc private func save() {
        ThemeManager.shared.selectedPreset = selectedPreset
        ThemeManager.shared.customKeyBackground = customKeyBackground
        ThemeManager.shared.customKeyText = customKeyText
        ThemeManager.shared.customAccent = customAccent
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Preview helpers

    private func currentPreviewTheme() -> KeyboardTheme {
        switch selectedPreset {
        case .system:
            return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        case .light: return .light
        case .dark: return .dark
        case .amoledBlack: return .amoledBlack
        case .highContrast: return .highContrast
        case .custom:
            return KeyboardTheme(
                keyBackground: customKeyBackground,
                keyText: customKeyText,
                keyboardBackground: UIColor(white: 0.82, alpha: 1),
                accent: customAccent,
                toolbarBackground: .systemGroupedBackground
            )
        }
    }

    private func refreshPreview() {
        previewView?.applyTheme(currentPreviewTheme())
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .preset: return ThemePreset.allCases.count
        case .customColors: return selectedPreset == .custom ? 3 : 0
        case .preview: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .preset: return "Theme Preset"
        case .customColors: return selectedPreset == .custom ? "Custom Colors" : nil
        case .preview: return "Preview"
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Section(rawValue: indexPath.section) == .preview {
            return 140
        }
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .preset:
            let preset = ThemePreset.allCases[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: "preset")
            cell.textLabel?.text = preset.displayName
            cell.accessoryType = preset == selectedPreset ? .checkmark : .none
            return cell

        case .customColors:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "color")
            cell.accessoryType = .disclosureIndicator
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Key Background"
                cell.imageView?.image = colorSwatch(customKeyBackground)
            case 1:
                cell.textLabel?.text = "Key Text"
                cell.imageView?.image = colorSwatch(customKeyText)
            default:
                cell.textLabel?.text = "Accent"
                cell.imageView?.image = colorSwatch(customAccent)
            }
            return cell

        case .preview:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "preview")
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .secondarySystemBackground

            let preview = KeyboardPreviewView()
            preview.translatesAutoresizingMaskIntoConstraints = false
            preview.applyTheme(currentPreviewTheme())
            cell.contentView.addSubview(preview)
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                preview.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                preview.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                preview.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            previewView = preview
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .preset:
            let newPreset = ThemePreset.allCases[indexPath.row]
            let wasCustom = selectedPreset == .custom
            selectedPreset = newPreset
            if wasCustom || newPreset == .custom {
                tableView.reloadSections([Section.preset.rawValue, Section.customColors.rawValue], with: .automatic)
            } else {
                tableView.reloadSections([Section.preset.rawValue], with: .none)
            }
            refreshPreview()

        case .customColors:
            presentColorPicker(for: indexPath.row)

        case .preview:
            break
        }
    }

    // MARK: - Color picker

    private func presentColorPicker(for row: Int) {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        switch row {
        case 0:
            picker.selectedColor = customKeyBackground
            activeColorTarget = .customKeyBackground
        case 1:
            picker.selectedColor = customKeyText
            activeColorTarget = .customKeyText
        default:
            picker.selectedColor = customAccent
            activeColorTarget = .customAccent
        }
        picker.supportsAlpha = false
        present(picker, animated: true)
    }

    // MARK: - Swatch helper

    private func colorSwatch(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 28, height: 28)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6).fill()
            UIColor.separator.setStroke()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5), cornerRadius: 6)
            path.lineWidth = 1
            path.stroke()
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension ThemeSettingsViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        switch activeColorTarget {
        case .customKeyBackground:
            customKeyBackground = color
        case .customKeyText:
            customKeyText = color
        case .customAccent:
            customAccent = color
        default:
            break
        }
        tableView.reloadSections([Section.customColors.rawValue], with: .none)
        refreshPreview()
    }
}

// MARK: - KeyboardPreviewView

final class KeyboardPreviewView: UIView {

    private let row1Keys = ["Q", "W", "E", "R", "T", "Y"]
    private let row2Keys = ["A", "S", "D", "F", "G"]
    private let row3Keys = ["space", "return"]

    private var keyViews: [UIView] = []
    private var containerBg: UIView!
    private var toolbarBg: UIView!
    private var accentDot: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 10
        layer.masksToBounds = true

        toolbarBg = UIView()
        toolbarBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbarBg)

        accentDot = UIView()
        accentDot.translatesAutoresizingMaskIntoConstraints = false
        accentDot.layer.cornerRadius = 8
        toolbarBg.addSubview(accentDot)

        containerBg = UIView()
        containerBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerBg)

        NSLayoutConstraint.activate([
            toolbarBg.topAnchor.constraint(equalTo: topAnchor),
            toolbarBg.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBg.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBg.heightAnchor.constraint(equalToConstant: 28),

            accentDot.leadingAnchor.constraint(equalTo: toolbarBg.leadingAnchor, constant: 8),
            accentDot.centerYAnchor.constraint(equalTo: toolbarBg.centerYAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 44),
            accentDot.heightAnchor.constraint(equalToConstant: 16),

            containerBg.topAnchor.constraint(equalTo: toolbarBg.bottomAnchor),
            containerBg.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerBg.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerBg.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let rows = [row1Keys, row2Keys, row3Keys]
        var prevRow: UIView?
        for (ri, rowKeys) in rows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 3
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            for key in rowKeys {
                let v = UIView()
                v.layer.cornerRadius = 3
                if ri == 2 {
                    let lbl = UILabel()
                    lbl.text = key
                    lbl.font = .systemFont(ofSize: 7)
                    lbl.textAlignment = .center
                    lbl.translatesAutoresizingMaskIntoConstraints = false
                    v.addSubview(lbl)
                    NSLayoutConstraint.activate([
                        lbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                        lbl.centerYAnchor.constraint(equalTo: v.centerYAnchor)
                    ])
                    keyViews.append(lbl)
                } else {
                    let lbl = UILabel()
                    lbl.text = key
                    lbl.font = .systemFont(ofSize: 8, weight: .medium)
                    lbl.textAlignment = .center
                    lbl.translatesAutoresizingMaskIntoConstraints = false
                    v.addSubview(lbl)
                    NSLayoutConstraint.activate([
                        lbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                        lbl.centerYAnchor.constraint(equalTo: v.centerYAnchor)
                    ])
                    keyViews.append(lbl)
                }
                keyViews.append(v)
                rowStack.addArrangedSubview(v)
            }
            containerBg.addSubview(rowStack)
            NSLayoutConstraint.activate([
                rowStack.leadingAnchor.constraint(equalTo: containerBg.leadingAnchor, constant: 4),
                rowStack.trailingAnchor.constraint(equalTo: containerBg.trailingAnchor, constant: -4),
                rowStack.heightAnchor.constraint(equalToConstant: 22)
            ])
            if let prev = prevRow {
                rowStack.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 3).isActive = true
            } else {
                rowStack.topAnchor.constraint(equalTo: containerBg.topAnchor, constant: 4).isActive = true
            }
            prevRow = rowStack
        }
    }

    func applyTheme(_ theme: KeyboardTheme) {
        toolbarBg.backgroundColor = theme.toolbarBackground
        accentDot.backgroundColor = theme.accent
        containerBg.backgroundColor = theme.keyboardBackground
        for view in keyViews {
            if let label = view as? UILabel {
                label.textColor = theme.keyText
            } else {
                view.backgroundColor = theme.keyBackground
            }
        }
    }
}
