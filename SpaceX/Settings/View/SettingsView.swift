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
        backgroundColor = .black
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
        settingsLabel.textColor = .white
        settingsLabel.numberOfLines = 0
        settingsLabel.font = UIFont(name: "LabGrotesque-Medium", size: 16)
        settingsLabel.translatesAutoresizingMaskIntoConstraints = false

        settingsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupCloseButton() {
        addSubview(closeButton)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "LabGrotesque-Bold", size: 16)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().inset(24)
        }
    }
    
    private func setupLabels() {
        [heightLabel, diameterLabel, massLabel, payloadWeightsLabel].forEach {
            $0.textColor = .white
            $0.font = UIFont(name: "LabGrotesque-Medium", size: 16)
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
        labelStackView.spacing = 24
        labelStackView.distribution = .equalSpacing
        
        horizontalStacks.forEach { labelStackView.addArrangedSubview($0) }
        
        addSubview(labelStackView)
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        labelStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(112)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().inset(28)
        }
    }
    
    private func createHorizontalStack(label: UILabel, firstText: String, secondText: String, initialState: Bool, index: Int) -> UIStackView {
        let stackView = UIStackView()
        let toggleView = CustomToggleView(firstText: firstText, secondText: secondText, initialState: initialState)

        toggleView.onToggle = { [weak self] isOn in
            self?.viewModel.toggleState(at: index)
        }
        
        // сообщает SettingsView, что переключатель изменил состояние,
        // и вызывает метод viewModel.toggleState(at: index),
        // чтобы обновить состояние в SettingsViewModel и сохранить его в UserDefaults.
        
        stackView.axis = .horizontal
        stackView.spacing = 20
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

