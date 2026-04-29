import UIKit
import SnapKit

final class CustomToggleView: UIView {
    
    private let grayRectangle = UIView()
    private let toggleIndicator = UIView()
    private let measureStackView = UIStackView()
    private let firstMeasure = UILabel()
    private let secondMeasure = UILabel()
    private var leadingConstraint: Constraint?
    
    var isOn: Bool = false {
        didSet {
            updateUI(animated: true)
        }
    }
    
    var onToggle: ((Bool) -> Void)?
    
    init(firstText: String, secondText: String, initialState: Bool = true) {
        self.isOn = initialState
        super.init(frame: .zero)
        setupViews(firstText: firstText, secondText: secondText)
        updateUI(animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(firstText: String, secondText: String) {
        setupGrayRectangle()
        setupToggleIndicator()
        setupMeasureStackView()
        setupMeasureLabels(firstText: firstText, secondText: secondText)
    }
    
    private func setupGrayRectangle() {
        addSubview(grayRectangle)
        grayRectangle.layer.cornerRadius = Constants.cornerRadius
        grayRectangle.backgroundColor = AppColors.cardGray
        grayRectangle.isUserInteractionEnabled = true
        
        grayRectangle.snp.makeConstraints { make in
            make.width.equalTo(Constants.toggleWidth)
            make.height.equalTo(Constants.toggleHeight)
            make.edges.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        grayRectangle.addGestureRecognizer(tapGesture)
    }
    
    private func setupToggleIndicator() {
        grayRectangle.addSubview(toggleIndicator)
        toggleIndicator.layer.cornerRadius = Constants.cornerRadius
        toggleIndicator.backgroundColor = AppColors.white
        
        toggleIndicator.snp.makeConstraints { make in
            make.width.equalTo(Constants.indicatorWidth)
            make.height.equalTo(Constants.indicatorHeight)
            make.centerY.equalToSuperview()
            leadingConstraint = make.leading.equalToSuperview().offset(Constants.toggleOffOffset).constraint
        }
    }
    
    private func setupMeasureStackView() {
        grayRectangle.addSubview(measureStackView)
        measureStackView.axis = .horizontal
        measureStackView.spacing = Constants.measureStackSpacing
        measureStackView.distribution = .equalSpacing
        measureStackView.alignment = .center
        
        measureStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupMeasureLabels(firstText: String, secondText: String) {
        firstMeasure.text = firstText
        firstMeasure.textColor = AppColors.activeBlack07
        firstMeasure.font = AppFonts.bold14
        firstMeasure.numberOfLines = 0
        
        secondMeasure.text = secondText
        secondMeasure.textColor = AppColors.textGray56
        secondMeasure.font = AppFonts.bold14
        secondMeasure.numberOfLines = 0
        
        measureStackView.addArrangedSubview(firstMeasure)
        measureStackView.addArrangedSubview(secondMeasure)
    }
    
    @objc private func handleTap() {
        isOn.toggle()
        onToggle?(isOn)
    }
    
    private func updateUI(animated: Bool) {
        guard let leadingConstraint = leadingConstraint else { return }
        
        let updateBlock = {
            leadingConstraint.update(offset: self.isOn ? Constants.toggleOnOffset : Constants.toggleOffOffset)
            self.grayRectangle.layoutIfNeeded()
            self.firstMeasure.textColor = self.isOn ? AppColors.textGray56 : AppColors.activeBlack07
            self.secondMeasure.textColor = self.isOn ? AppColors.activeBlack07 : AppColors.textGray56
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, delay: 0, options: .curveEaseOut, animations: updateBlock)
        } else {
            updateBlock()
        }
    }
}

private extension CustomToggleView {
    enum Constants {
        static let toggleWidth: CGFloat = 115
        static let toggleHeight: CGFloat = 40
        static let indicatorWidth: CGFloat = 56
        static let indicatorHeight: CGFloat = 34
        static let toggleOnOffset: CGFloat = 56
        static let toggleOffOffset: CGFloat = 3
        static let cornerRadius: CGFloat = 8
        static let measureStackSpacing: CGFloat = 40
        static let animationDuration: TimeInterval = 0.3
    }
}
