import UIKit

final class SettingsViewController: UIViewController {

    private let previewSwitch = UISwitch()
    private let intervalSlider = UISlider()
    private let intervalLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        // Preview toggle section
        let previewSection = makeSection(
            title: "Preview Before Save",
            subtitle: "Show result before saving to Photos"
        )
        previewSwitch.addTarget(self, action: #selector(previewToggled), for: .valueChanged)
        previewSection.addArrangedSubview(previewSwitch)
        stack.addArrangedSubview(previewSection)

        // Frame interval section
        let intervalSection = makeSection(
            title: "Frame Interval",
            subtitle: "Time between sampled frames: \(String(format: "%.1f", UserSettings.frameInterval))s"
        )
        intervalLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        intervalLabel.text = String(format: "%.1fs", UserSettings.frameInterval)
        intervalSection.addArrangedSubview(intervalLabel)

        intervalSlider.minimumValue = 0.2
        intervalSlider.maximumValue = 0.6
        intervalSlider.value = Float(UserSettings.frameInterval)
        intervalSlider.addTarget(self, action: #selector(intervalChanged), for: .valueChanged)
        intervalSection.addArrangedSubview(intervalSlider)
        stack.addArrangedSubview(intervalSection)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func makeSection(title: String, subtitle: String) -> UIStackView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 8
        section.backgroundColor = .secondarySystemGroupedBackground
        section.layer.cornerRadius = 12
        section.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        section.isLayoutMarginsRelativeArrangement = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        section.addArrangedSubview(titleLabel)
        section.addArrangedSubview(subtitleLabel)
        return section
    }

    private func loadCurrentSettings() {
        previewSwitch.isOn = UserSettings.previewBeforeSave
        intervalSlider.value = Float(UserSettings.frameInterval)
        intervalLabel.text = String(format: "%.1fs", UserSettings.frameInterval)
    }

    @objc private func previewToggled() {
        UserSettings.previewBeforeSave = previewSwitch.isOn
    }

    @objc private func intervalChanged() {
        let value = round(intervalSlider.value * 10) / 10
        intervalSlider.value = value
        UserSettings.frameInterval = TimeInterval(value)
        intervalLabel.text = String(format: "%.1fs", value)
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
