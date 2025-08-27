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
    private var toggleViews = [CustomToggleView]()
    
    private let viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        backgroundColor = AppColors.black
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        setupSettingsLabel()
        setupCloseButton()
        setupLabels()
        setupLabelStackView()
    }
    
    private func setupSettingsLabel() {
        addSubview(settingsLabel)
        settingsLabel.text = "Настройки"
        settingsLabel.textColor = AppColors.white
        settingsLabel.numberOfLines = 0
        settingsLabel.font = AppFonts.medium16
        settingsLabel.translatesAutoresizingMaskIntoConstraints = false

        settingsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.settingsLabelTopOffset)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupCloseButton() {
        addSubview(closeButton)
        closeButton.setTitle("Закрыть", for: .normal)
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
        
        heightLabel.text = "Высота"
        diameterLabel.text = "Диаметр"
        massLabel.text = "Масса"
        payloadWeightsLabel.text = "Полезная нагрузка"
    }
    
    private func setupLabelStackView() {
        let toggleStates = viewModel.getToggleStates()
        
        let horizontalStacks = [
            createHorizontalStack(label: heightLabel, firstText: "m", secondText: "ft", initialState: toggleStates[0], index: 0),
            createHorizontalStack(label: diameterLabel, firstText: "m", secondText: "ft", initialState: toggleStates[1], index: 1),
            createHorizontalStack(label: massLabel, firstText: "kg", secondText: "lb", initialState: toggleStates[2], index: 2),
            createHorizontalStack(label: payloadWeightsLabel, firstText: "kg", secondText: "lb", initialState: toggleStates[3], index: 3),
        ]
        
        labelStackView.axis = .vertical
        labelStackView.spacing = Constants.stackViewSpacing
        labelStackView.distribution = .equalSpacing
        
        horizontalStacks.forEach { labelStackView.addArrangedSubview($0) }
        
        addSubview(labelStackView)
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
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
            self?.viewModel.toggleState(at: index)
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
    
    func saveSettings() {
        viewModel.saveSettings()
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
