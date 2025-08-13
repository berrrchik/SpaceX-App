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
    private var toggleIndicators = [UIView]()
    private var toggleStates = [Bool]()
    private var toggleLeadingConstraints = [Constraint?]()
    private var grayRectangles = [UIView]()
    
    init() {
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
        let horizontalStacks = [
            createHorizontalStack(label: heightLabel, firstText: "m", secondText: "ft"),
            createHorizontalStack(label: diameterLabel, firstText: "m", secondText: "ft"),
            createHorizontalStack(label: massLabel, firstText: "kg", secondText: "lb"),
            createHorizontalStack(label: payloadWeightsLabel, firstText: "kg", secondText: "lb")
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
    
    private func createHorizontalStack(label: UILabel, firstText: String, secondText: String) -> UIStackView {
        let stackView = UIStackView()
        let grayRectangle = UIView()
        let toggleIndicator = UIView()
        
        let measureStackView = UIStackView()
        let firstMeasure = UILabel()
        let secondMeasure = UILabel()
        
        measureStackView.axis = .horizontal
        measureStackView.spacing = 40
        measureStackView.distribution = .equalSpacing
        measureStackView.alignment = .center
        
        firstMeasure.text = firstText
        firstMeasure.textColor =  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)
        firstMeasure.font = UIFont(name: "LabGrotesque-Bold", size: 14)
        firstMeasure.numberOfLines = 0
        
        secondMeasure.text = secondText
        secondMeasure.textColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
        secondMeasure.font = UIFont(name: "LabGrotesque-Bold", size: 14)
        secondMeasure.numberOfLines = 0
        
        measureStackView.addArrangedSubview(firstMeasure)
        measureStackView.addArrangedSubview(secondMeasure)
        
        toggleIndicator.layer.cornerRadius = 8
        toggleIndicator.backgroundColor = .white
        toggleIndicator.isUserInteractionEnabled = true
        
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .fill
        stackView.alignment = .center
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(grayRectangle)
        
        grayRectangle.addSubview(toggleIndicator)
        grayRectangle.addSubview(measureStackView)

        
        grayRectangle.layer.cornerRadius = 8
        grayRectangle.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.00)
        
        grayRectangle.snp.makeConstraints { make in
            make.width.equalTo(115)
            make.height.equalTo(40)
        }
        
        measureStackView.snp.makeConstraints { make in
            make.center.equalTo(grayRectangle)
        }
        
        var leadingConstraint: Constraint?
        toggleIndicator.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(34)
            make.centerY.equalTo(grayRectangle)
            leadingConstraint = make.leading.equalTo(grayRectangle).offset(3).constraint
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleTapped(_:)))
        grayRectangle.addGestureRecognizer(tapGesture)
        grayRectangle.isUserInteractionEnabled = true
        
        toggleIndicators.append(toggleIndicator)
        toggleStates.append(false)
        toggleLeadingConstraints.append(leadingConstraint)
        grayRectangles.append(grayRectangle)
        
        return stackView
    }
    
    @objc private func toggleTapped(_ gesture: UITapGestureRecognizer) {
        guard let grayRectangle = gesture.view else { return }
        
        if let index = grayRectangles.firstIndex(of: grayRectangle) {
            guard index < toggleIndicators.count, let leadingConstraint = toggleLeadingConstraints[index] else { return }
            let toggleIndicator = toggleIndicators[index]
            let isOn = !toggleStates[index]
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                leadingConstraint.update(offset: isOn ? 56 : 3)
                grayRectangle.layoutIfNeeded()
                
                if let measureStackView = grayRectangle.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                    if let firstMeasure = measureStackView.arrangedSubviews.first as? UILabel,
                       let secondMeasure = measureStackView.arrangedSubviews.dropFirst().first as? UILabel {
                        
                        let activeColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)
                        let inactiveColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
                        
                        firstMeasure.textColor = isOn ? inactiveColor : activeColor
                        secondMeasure.textColor = isOn ? activeColor : inactiveColor
                    }
                }
            }
            toggleStates[index] = isOn
        }
    }
}
