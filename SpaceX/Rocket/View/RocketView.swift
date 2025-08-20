import UIKit
import SnapKit
import Kingfisher

final class RocketView: UIView {
    
    let scrollView = UIScrollView()
    
    var imageURL: URL?
    let imageView = UIImageView()
    let imageContainer = UIView()
    
    let rocketNameLabel = UILabel()
    let settingsButton = UIButton()
    
    let textBacking = UIView()
    let textContainer = UIView()
    
    let squareView: SquareView
    let labelStackView = UIStackView()
    
    let firstFlightLabel = UILabel()
    let firstFlight = UILabel()
    
    let countryLabel = UILabel()
    let country = UILabel()
    
    let costPerLaunchLabel = UILabel()
    let costPerLaunch = UILabel()
    
    let firstStageTextLabel = UILabel()
    
    let enginesCountFirstStageLabel = UILabel()
    let enginesCountFirstStage = UILabel()
    
    let fuelAmountTonsFirstStageLabel = UILabel()
    let fuelAmountTonsFirstStage = UILabel()
    
    let burnTimeSECFirstStageLabel = UILabel()
    let burnTimeSECFirstStage = UILabel()
    
    let secondStageTextLabel = UILabel()
    
    let enginesCountSecondtStageLabel = UILabel()
    let enginesCountSecondtStage = UILabel()
    
    let fuelAmountTonsSecondtStageLabel = UILabel()
    let fuelAmountTonsSecondtStage = UILabel()
    
    let burnTimeSECSecondtStageLabel = UILabel()
    let burnTimeSECSecondtStage = UILabel()
    
    let showLaunchesButton = UIButton()
    
    init(viewModel: SettingsViewModel) {
        self.squareView = SquareView(viewModel: viewModel)
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with rocket: RocketElement, imageURL: URL?) {
        self.imageURL = imageURL
        
        if let imageURL = imageURL {
            imageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "SomethingWentWrong"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            imageView.image = UIImage(named: "SomethingWentWrong")
        }
        
        rocketNameLabel.text = rocket.name
        
        firstFlight.text = rocket.getFirstFlightDate
        country.text = rocket.country
        costPerLaunch.text = String(rocket.costPerLaunch)
        
        enginesCountFirstStage.text = String(rocket.firstStage.engines)
        fuelAmountTonsFirstStage.text = String(rocket.firstStage.fuelAmountTons)
        burnTimeSECFirstStage.text = String(rocket.firstStage.burnTimeSEC ?? 0)
        
        enginesCountSecondtStage.text = String(rocket.secondStage.engines)
        fuelAmountTonsSecondtStage.text = String(rocket.secondStage.fuelAmountTons)
        burnTimeSECSecondtStage.text = String(rocket.secondStage.burnTimeSEC ?? 0)
        
        squareView.configure(with: [
            (metricValue: rocket.height.meters, imperialValue: rocket.height.feet, metricMeasure: "Высота, m", imperialMeasure: "Высота, ft"),
            (metricValue: rocket.diameter.meters, imperialValue: rocket.diameter.feet, metricMeasure: "Диаметр, m", imperialMeasure: "Диаметр, ft"),
            (metricValue: rocket.mass.kg, imperialValue: rocket.mass.lb, metricMeasure: "Масса, kg", imperialMeasure: "Масса, lb"),
            (metricValue: rocket.payloadWeights.first?.kg, imperialValue: rocket.payloadWeights.first?.lb, metricMeasure: "Полезная нагрузка, kg", imperialMeasure: "Полезная нагрузка, lb")
        ])
    }
    
    private func setupView() {
        setupScrollView()
        setupImageContainer()
        setupImageView()
        setupTextContainer()
        setupTextBacking()
        setupRocketNameLabel()
        setupSettingsButton()
        setupSquareView()
        setupLabels()
        setupLabelStackView()
        setupShowLaunchesButton()
    }
    
    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        
        scrollView.addSubview(imageContainer)
        scrollView.addSubview(imageView)
        scrollView.addSubview(textBacking)
        scrollView.addSubview(textContainer)
        scrollView.addSubview(squareView)
        scrollView.addSubview(settingsButton)
        scrollView.addSubview(labelStackView)
        scrollView.addSubview(showLaunchesButton)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    private func setupImageContainer() {
        imageContainer.backgroundColor = .darkGray
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(scrollView)
            make.left.right.equalTo(self)
            make.height.equalTo(imageContainer.snp.width).multipliedBy(0.8)
        }
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.snp.makeConstraints { make in
            make.left.right.equalTo(imageContainer)
            make.top.equalTo(self).priority(.high)
            make.height.greaterThanOrEqualTo(imageContainer.snp.height).priority(.required)
            make.bottom.equalTo(imageContainer.snp.bottom)
        }
    }
    
    private func setupTextContainer() {
        textContainer.backgroundColor = .clear
        textContainer.addSubview(rocketNameLabel)
        
        textContainer.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(-30)
            make.left.right.equalTo(self)
            make.bottom.equalTo(scrollView)
        }
    }
    
    private func setupTextBacking() {
        textBacking.backgroundColor = .black
        textBacking.layer.cornerRadius = 32
        textBacking.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textBacking.clipsToBounds = true
        
        textBacking.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(imageContainer.snp.bottom).offset(-40)
            make.bottom.equalTo(self)
        }
    }
    
    private func setupRocketNameLabel() {
        rocketNameLabel.textColor = .white
        rocketNameLabel.numberOfLines = 0
        rocketNameLabel.font = UIFont(name: "LabGrotesque-Bold", size: 32)
        rocketNameLabel.snp.makeConstraints { make in
            make.top.equalTo(textBacking.snp.top).inset(48)
            make.left.equalTo(textBacking).offset(32)
        }
    }
    
    private func setupSettingsButton() {
        settingsButton.setImage(UIImage(systemName: "gearshape", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32.0))?.withTintColor(UIColor.white), for: .normal)
        settingsButton.tintColor = .white
        
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(textBacking.snp.top).inset(48)
            make.right.equalTo(textBacking).inset(32)
        }
    }
    
    private func setupSquareView() {
        scrollView.addSubview(squareView)
        
        squareView.snp.makeConstraints { make in
            make.top.equalTo(rocketNameLabel.snp.bottom).offset(32)
            make.leading.equalTo(textContainer).inset(32)
            make.trailing.equalTo(textContainer)
            make.height.equalTo(96)
        }
    }
    
    private func setupLabels() {
        [firstFlightLabel, countryLabel, costPerLaunchLabel, enginesCountFirstStageLabel, fuelAmountTonsFirstStageLabel, burnTimeSECFirstStageLabel, enginesCountSecondtStageLabel, fuelAmountTonsSecondtStageLabel, burnTimeSECSecondtStageLabel].forEach {
            $0.textColor = UIColor(red: 0.79, green: 0.79, blue: 0.79, alpha: 1.00)
            $0.font = UIFont(name: "LabGrotesque-Regular", size: 16)
            $0.textAlignment = .left
        }
        
        [firstFlight, country, costPerLaunch, enginesCountFirstStage, fuelAmountTonsFirstStage, burnTimeSECFirstStage, enginesCountSecondtStage, fuelAmountTonsSecondtStage, burnTimeSECSecondtStage].forEach {
            $0.textColor = .white
            $0.font = UIFont(name: "LabGrotesque-Medium", size: 16)
            $0.textAlignment = .right
        }
        
        [firstStageTextLabel, secondStageTextLabel].forEach {
            $0.textColor = .white
            $0.font = UIFont(name: "LabGrotesque-Bold", size: 16)
        }
        
        firstStageTextLabel.text = "ПЕРВАЯ СТУПЕНЬ"
        secondStageTextLabel.text = "ВТОРАЯ СТУПЕНЬ"
        
        firstFlightLabel.text = "Первый запуск"
        countryLabel.text = "Страна"
        costPerLaunchLabel.text = "Стоимость запуска"
        
        enginesCountFirstStageLabel.text = "Количество двигателей"
        fuelAmountTonsFirstStageLabel.text = "Количество топлива"
        burnTimeSECFirstStageLabel.text = "Время сгорания"
        
        enginesCountSecondtStageLabel.text = "Количество двигателей"
        fuelAmountTonsSecondtStageLabel.text = "Количество топлива"
        burnTimeSECSecondtStageLabel.text = "Время сгорания"
    }
    
    private func setupLabelStackView() {
        labelStackView.axis = .vertical
        labelStackView.spacing = 40
        labelStackView.distribution = .equalSpacing
        
        let infoGroup = UIStackView()
        infoGroup.axis = .vertical
        infoGroup.spacing = 16
        [createHorizontalStack(label: firstFlightLabel, value: firstFlight),
         createHorizontalStack(label: countryLabel, value: country),
         createHorizontalStack(label: costPerLaunchLabel, value: costPerLaunch)].forEach {
            infoGroup.addArrangedSubview($0)
        }
        
        let firstStageGroup = UIStackView()
        firstStageGroup.axis = .vertical
        firstStageGroup.spacing = 16
        firstStageGroup.addArrangedSubview(firstStageTextLabel)
        [createHorizontalStack(label: enginesCountFirstStageLabel, value: enginesCountFirstStage),
         createHorizontalStack(label: fuelAmountTonsFirstStageLabel, value: fuelAmountTonsFirstStage),
         createHorizontalStack(label: burnTimeSECFirstStageLabel, value: burnTimeSECFirstStage)].forEach {
            firstStageGroup.addArrangedSubview($0)
        }
        
        let secondStageGroup = UIStackView()
        secondStageGroup.axis = .vertical
        secondStageGroup.spacing = 16
        secondStageGroup.addArrangedSubview(secondStageTextLabel)
        [createHorizontalStack(label: enginesCountSecondtStageLabel, value: enginesCountSecondtStage),
         createHorizontalStack(label: fuelAmountTonsSecondtStageLabel, value: fuelAmountTonsSecondtStage),
         createHorizontalStack(label: burnTimeSECSecondtStageLabel, value: burnTimeSECSecondtStage)].forEach {
            secondStageGroup.addArrangedSubview($0)
        }
        
        labelStackView.addArrangedSubview(infoGroup)
        labelStackView.addArrangedSubview(firstStageGroup)
        labelStackView.addArrangedSubview(secondStageGroup)
        
        labelStackView.snp.makeConstraints { make in
            make.top.equalTo(squareView.snp.bottom).offset(40)
            make.leading.equalTo(textContainer).offset(32)
            make.trailing.equalTo(textContainer).inset(32)
        }
    }
    
    private func createHorizontalStack(label: UILabel, value: UILabel) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .fill
        stackView.alignment = .center
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(value)
        
        return stackView
    }
    
    private func setupShowLaunchesButton() {
        showLaunchesButton.setTitle("Посмотреть запуски", for: .normal)
        showLaunchesButton.titleLabel?.font = UIFont(name: "LabGrotesque-Bold", size: 18)
        showLaunchesButton.tintColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        showLaunchesButton.backgroundColor = UIColor(.gray.opacity(0.3))
        showLaunchesButton.layer.cornerRadius = 16
        
        showLaunchesButton.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.top.equalTo(labelStackView.snp.bottom).offset(40)
            make.leading.equalTo(textContainer).offset(32)
            make.trailing.equalTo(textContainer).inset(32)
            make.bottom.equalTo(textContainer).inset(40)
        }
    }
    
    func adjustScrollViewInsets(safeAreaInsets: UIEdgeInsets) {
        scrollView.scrollIndicatorInsets = safeAreaInsets
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: safeAreaInsets.bottom, right: 0)
    }
}

extension RocketView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            let offset = abs(scrollView.contentOffset.y)
            imageView.snp.updateConstraints { make in
                make.top.equalTo(self).offset(-offset)
            }
        } else {
            imageView.snp.updateConstraints { make in
                make.top.equalTo(self)
            }
        }
    }
}

#Preview {
    let rocketView = RocketView(viewModel: SettingsViewModel())
    let viewController = UIViewController()
    viewController.view = rocketView
    return viewController
}
