import UIKit
import SnapKit

final class SettingsView: UIView {
    let settingsLabel = UILabel()
    let closeButton = UIButton()

    let heightLabel = UILabel()
    let diameterLabel = UILabel()
    let massLabel = UILabel()
    let payloadWeightsLabel = UILabel()

    let labelStackView = UIStackView()
    private(set) var toggleViews = [CustomToggleView]()

    var onToggleChanged: ((Int, Bool) -> Void)?

    init(toggleStates: [Bool]) {
        super.init(frame: .zero)
        backgroundColor = AppColors.black
        setupViews(toggleStates: toggleStates)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(toggleStates: [Bool]) {
        setupSettingsLabel()
        setupCloseButton()
        setupLabels()
        setupLabelStackView(toggleStates: toggleStates)
    }

    private func setupSettingsLabel() {
        addSubview(settingsLabel)
        settingsLabel.text = L10n.settingsTitle
        settingsLabel.textColor = AppColors.white
        settingsLabel.numberOfLines = 0
        settingsLabel.font = AppFonts.medium16

        settingsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.settingsLabelTopOffset)
            make.centerX.equalToSuperview()
        }
    }

    private func setupCloseButton() {
        addSubview(closeButton)
        closeButton.setTitle(L10n.settingsClose, for: .normal)
        closeButton.setTitleColor(AppColors.white, for: .normal)
        closeButton.titleLabel?.font = AppFonts.bold16

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.closeButtonTopOffset)
            make.trailing.equalToSuperview().inset(Constants.closeButtonTrailingMargin)
        }
    }

    private func setupLabels() {
        [heightLabel, diameterLabel, massLabel, payloadWeightsLabel].forEach {
            $0.textColor = AppColors.white
            $0.font = AppFonts.medium16
        }

        heightLabel.text = L10n.settingsHeight
        diameterLabel.text = L10n.settingsDiameter
        massLabel.text = L10n.settingsMass
        payloadWeightsLabel.text = L10n.settingsPayload
    }

    private func setupLabelStackView(toggleStates: [Bool]) {
        let safeStates = toggleStates + Array(repeating: false, count: max(0, 4 - toggleStates.count))

        let horizontalStacks = [
            createHorizontalStack(label: heightLabel, firstText: "m", secondText: "ft", initialState: safeStates[0], index: 0),
            createHorizontalStack(label: diameterLabel, firstText: "m", secondText: "ft", initialState: safeStates[1], index: 1),
            createHorizontalStack(label: massLabel, firstText: "kg", secondText: "lb", initialState: safeStates[2], index: 2),
            createHorizontalStack(label: payloadWeightsLabel, firstText: "kg", secondText: "lb", initialState: safeStates[3], index: 3)
        ]

        labelStackView.axis = .vertical
        labelStackView.spacing = Constants.stackViewSpacing
        labelStackView.distribution = .equalSpacing
        horizontalStacks.forEach { labelStackView.addArrangedSubview($0) }

        addSubview(labelStackView)
        labelStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.stackViewTopOffset)
            make.leading.equalToSuperview().offset(Constants.stackViewHorizontalMargin)
            make.trailing.equalToSuperview().inset(Constants.stackViewHorizontalMargin)
        }
    }

    private func createHorizontalStack(
        label: UILabel,
        firstText: String,
        secondText: String,
        initialState: Bool,
        index: Int
    ) -> UIStackView {
        let stackView = UIStackView()
        let toggleView = CustomToggleView(firstText: firstText, secondText: secondText, initialState: initialState)

        toggleView.onToggle = { [weak self] isOn in
            self?.onToggleChanged?(index, isOn)
        }

        stackView.axis = .horizontal
        stackView.spacing = Constants.horizontalStackSpacing
        stackView.distribution = .fill
        stackView.alignment = .center

        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(toggleView)

        toggleViews.append(toggleView)

        return stackView
    }
}

private extension SettingsView {
    enum Constants {
        static let settingsLabelTopOffset: CGFloat = 24
        static let closeButtonTopOffset: CGFloat = 18
        static let closeButtonTrailingMargin: CGFloat = 24
        static let stackViewTopOffset: CGFloat = 112
        static let stackViewHorizontalMargin: CGFloat = 28
        static let stackViewSpacing: CGFloat = 24
        static let horizontalStackSpacing: CGFloat = 20
    }
}
