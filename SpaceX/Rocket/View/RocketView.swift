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
                    .transition(.fade(Constants.imageFadeDuration)),
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
        burnTimeSECFirstStage.text = String(rocket.firstStage.burnTimeSec ?? 0)
        
        enginesCountSecondtStage.text = String(rocket.secondStage.engines)
        fuelAmountTonsSecondtStage.text = String(rocket.secondStage.fuelAmountTons)
        burnTimeSECSecondtStage.text = String(rocket.secondStage.burnTimeSec ?? 0)
        
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
        imageContainer.backgroundColor = AppColors.darkGray
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(scrollView)
            make.left.right.equalTo(self)
            make.height.equalTo(imageContainer.snp.width).multipliedBy(Constants.imageContainerHeightRatio)
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
        textContainer.backgroundColor = AppColors.clear
        textContainer.addSubview(rocketNameLabel)
        
        textContainer.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(-Constants.textContainerTopOffset)
            make.left.right.equalTo(self)
            make.bottom.equalTo(scrollView)
        }
    }
    
    private func setupTextBacking() {
        textBacking.backgroundColor = AppColors.black
        textBacking.layer.cornerRadius = Constants.textBackingCornerRadius
        textBacking.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textBacking.clipsToBounds = true
        
        textBacking.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(imageContainer.snp.bottom).offset(-Constants.textBackingTopOffset)
            make.bottom.equalTo(self)
        }
    }
    
    private func setupRocketNameLabel() {
        rocketNameLabel.textColor = AppColors.white
        rocketNameLabel.numberOfLines = 0
        rocketNameLabel.font = AppFonts.bold32
        rocketNameLabel.snp.makeConstraints { make in
            make.top.equalTo(textBacking.snp.top).inset(Constants.rocketNameTopInset)
            make.left.equalTo(textBacking).offset(Constants.rocketNameHorizontalMargin)
        }
    }
    
    private func setupSettingsButton() {
        settingsButton.setImage(UIImage(systemName: "gearshape", withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.settingsButtonSize))?.withTintColor(AppColors.white), for: .normal)
        settingsButton.tintColor = AppColors.white
        
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(textBacking.snp.top).inset(Constants.rocketNameTopInset)
            make.right.equalTo(textBacking).inset(Constants.settingsButtonTrailingMargin)
        }
    }
    
    private func setupSquareView() {
        scrollView.addSubview(squareView)
        
        squareView.snp.makeConstraints { make in
            make.top.equalTo(rocketNameLabel.snp.bottom).offset(Constants.squareViewTopOffset)
            make.leading.equalTo(textContainer).inset(Constants.squareViewHorizontalMargin)
            make.trailing.equalTo(textContainer)
            make.height.equalTo(Constants.squareViewHeight)
        }
    }
    
    private func setupLabels() {
        [firstFlightLabel, countryLabel, costPerLaunchLabel, enginesCountFirstStageLabel, fuelAmountTonsFirstStageLabel, burnTimeSECFirstStageLabel, enginesCountSecondtStageLabel, fuelAmountTonsSecondtStageLabel, burnTimeSECSecondtStageLabel].forEach {
            $0.textColor = AppColors.labelGray79
            $0.font = AppFonts.regular16
            $0.textAlignment = .left
        }
        
        [firstFlight, country, costPerLaunch, enginesCountFirstStage, fuelAmountTonsFirstStage, burnTimeSECFirstStage, enginesCountSecondtStage, fuelAmountTonsSecondtStage, burnTimeSECSecondtStage].forEach {
            $0.textColor = AppColors.white
            $0.font = AppFonts.medium16
            $0.textAlignment = .right
        }
        
        [firstStageTextLabel, secondStageTextLabel].forEach {
            $0.textColor = AppColors.white
            $0.font = AppFonts.bold16
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
        labelStackView.spacing = Constants.labelStackViewSpacing
        labelStackView.distribution = .equalSpacing
        
        let infoGroup = UIStackView()
        infoGroup.axis = .vertical
        infoGroup.spacing = Constants.groupStackViewSpacing
        [createHorizontalStack(label: firstFlightLabel, value: firstFlight),
         createHorizontalStack(label: countryLabel, value: country),
         createHorizontalStack(label: costPerLaunchLabel, value: costPerLaunch)].forEach {
            infoGroup.addArrangedSubview($0)
        }
        
        let firstStageGroup = UIStackView()
        firstStageGroup.axis = .vertical
        firstStageGroup.spacing = Constants.groupStackViewSpacing
        firstStageGroup.addArrangedSubview(firstStageTextLabel)
        [createHorizontalStack(label: enginesCountFirstStageLabel, value: enginesCountFirstStage),
         createHorizontalStack(label: fuelAmountTonsFirstStageLabel, value: fuelAmountTonsFirstStage),
         createHorizontalStack(label: burnTimeSECFirstStageLabel, value: burnTimeSECFirstStage)].forEach {
            firstStageGroup.addArrangedSubview($0)
        }
        
        let secondStageGroup = UIStackView()
        secondStageGroup.axis = .vertical
        secondStageGroup.spacing = Constants.groupStackViewSpacing
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
            make.top.equalTo(squareView.snp.bottom).offset(Constants.labelStackViewTopOffset)
            make.leading.equalTo(textContainer).offset(Constants.labelStackViewHorizontalMargin)
            make.trailing.equalTo(textContainer).inset(Constants.labelStackViewHorizontalMargin)
        }
    }
    
    private func createHorizontalStack(label: UILabel, value: UILabel) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Constants.horizontalStackSpacing
        stackView.distribution = .fill
        stackView.alignment = .center
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(value)
        
        return stackView
    }
    
    private func setupShowLaunchesButton() {
        showLaunchesButton.setTitle("Посмотреть запуски", for: .normal)
        showLaunchesButton.titleLabel?.font = AppFonts.bold18
        showLaunchesButton.tintColor = AppColors.buttonTint96
        showLaunchesButton.backgroundColor = AppColors.buttonBackgroundGray
        showLaunchesButton.layer.cornerRadius = Constants.buttonCornerRadius
        
        showLaunchesButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.buttonHeight)
            make.top.equalTo(labelStackView.snp.bottom).offset(Constants.buttonTopOffset)
            make.leading.equalTo(textContainer).offset(Constants.buttonHorizontalMargin)
            make.trailing.equalTo(textContainer).inset(Constants.buttonHorizontalMargin)
            make.bottom.equalTo(textContainer).inset(Constants.buttonBottomMargin)
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

private extension RocketView {
    enum Constants {
        static let imageFadeDuration: TimeInterval = 0.3
        static let imageContainerHeightRatio: CGFloat = 0.8
        static let textContainerTopOffset: CGFloat = 30
        static let textBackingTopOffset: CGFloat = 40
        static let textBackingCornerRadius: CGFloat = 32
        static let rocketNameTopInset: CGFloat = 48
        static let rocketNameHorizontalMargin: CGFloat = 32
        static let settingsButtonSize: CGFloat = 32
        static let settingsButtonTrailingMargin: CGFloat = 32
        static let squareViewTopOffset: CGFloat = 32
        static let squareViewHorizontalMargin: CGFloat = 32
        static let squareViewHeight: CGFloat = 96
        static let labelStackViewTopOffset: CGFloat = 40
        static let labelStackViewHorizontalMargin: CGFloat = 32
        static let labelStackViewSpacing: CGFloat = 40
        static let groupStackViewSpacing: CGFloat = 16
        static let horizontalStackSpacing: CGFloat = 20
        static let buttonCornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 56
        static let buttonTopOffset: CGFloat = 40
        static let buttonHorizontalMargin: CGFloat = 32
        static let buttonBottomMargin: CGFloat = 40
    }
}

#Preview {
    let rocketView = RocketView(viewModel: SettingsViewModel())
    let viewController = UIViewController()
    viewController.view = rocketView
    return viewController
}
