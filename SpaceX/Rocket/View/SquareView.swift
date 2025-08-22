import UIKit
import SnapKit

final class SquareView: UIView {
    
    private let scrollStackView = UIScrollView()
    private let squareStack = UIStackView()
    private let viewModel: SettingsViewModel
    private var lastItems: [(metricValue: Any?, imperialValue: Any?, metricMeasure: String, imperialMeasure: String)] = []
    
    private var squares: [(square: UIView, valueLabel: UILabel, measureLabel: UILabel)] = []
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func configure(with items: [(metricValue: Any?, imperialValue: Any?, metricMeasure: String, imperialMeasure: String)]) {
        guard items.count == squares.count else { return }
        self.lastItems = items
        updateUI()
    }
    
    private func updateUI() {
        let toggleStates = viewModel.getToggleStates()
        
        for (index, item) in lastItems.enumerated() {
            let isImperial = toggleStates[index]
            let value = isImperial ? item.imperialValue : item.metricValue
            let measureText = isImperial ? item.imperialMeasure : item.metricMeasure
            
            let valueText: String
            if let doubleValue = value as? Double {
                valueText = doubleValue.isFinite ? String(format: "%.1f", doubleValue) : "–"
            } else if let intValue = value as? Int {
                valueText = intValue > 0 ? String(intValue) : "–"
            } else {
                valueText = "–"
            }
            squares[index].valueLabel.text = valueText
            squares[index].measureLabel.text = measureText
        }
    }
    
    private func setupViews() {
        setupScrollStackView()
        setupSquareStack()
        setupSquares()
    }
    
    private func setupScrollStackView() {
        scrollStackView.showsHorizontalScrollIndicator = false
        addSubview(scrollStackView)
        
        scrollStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(Constants.squareHeight)
        }
    }
    
    private func setupSquareStack() {
        squareStack.axis = .horizontal
        squareStack.spacing = Constants.stackSpacing
        squareStack.distribution = .equalSpacing
        scrollStackView.addSubview(squareStack)
        
        squareStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollStackView)
            make.leading.trailing.equalTo(scrollStackView)
            make.height.equalTo(scrollStackView)
            make.width.greaterThanOrEqualTo(scrollStackView).priority(.required)
        }
    }
    
    private func setupSquares() {
        for _ in 0..<Constants.squareCount {
            let square = UIView()
            square.backgroundColor = AppColors.cardGray
            square.layer.cornerRadius = Constants.squareCornerRadius
            
            let labelStack = UIStackView()
            labelStack.axis = .vertical
            labelStack.spacing = Constants.labelStackSpacing
            labelStack.alignment = .center
            
            let valueLabel = UILabel()
            valueLabel.textColor = AppColors.white
            valueLabel.numberOfLines = 0
            valueLabel.font = AppFonts.bold16
            
            let measureLabel = UILabel()
            measureLabel.textColor = AppColors.textGray56
            measureLabel.numberOfLines = 2
            measureLabel.font = AppFonts.regular14
            measureLabel.adjustsFontSizeToFitWidth = true
            measureLabel.minimumScaleFactor = Constants.labelMinimumScaleFactor
            measureLabel.lineBreakMode = .byWordWrapping
            
            labelStack.addArrangedSubview(valueLabel)
            labelStack.addArrangedSubview(measureLabel)
            
            square.addSubview(labelStack)
            labelStack.snp.makeConstraints { make in
                make.center.equalTo(square)
                make.leading.greaterThanOrEqualTo(square).offset(Constants.labelHorizontalMargin)
                make.trailing.lessThanOrEqualTo(square).offset(-Constants.labelHorizontalMargin)
            }
            
            square.snp.makeConstraints { make in
                make.width.height.equalTo(Constants.squareSize)
            }
            
            squareStack.addArrangedSubview(square)
            squares.append((square, valueLabel, measureLabel))
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }
    
    @objc private func settingsDidChange() {
        if !lastItems.isEmpty {
            updateUI()
        } else {
            squares.forEach { $0.valueLabel.text = "–"; $0.measureLabel.text = "" }
        }
    }
}

private extension SquareView {
    enum Constants {
        static let squareCount: Int = 4
        static let squareHeight: CGFloat = 96
        static let squareSize: CGFloat = 96
        static let squareCornerRadius: CGFloat = 32
        static let stackSpacing: CGFloat = 20
        static let labelStackSpacing: CGFloat = 5
        static let labelHorizontalMargin: CGFloat = 8
        static let labelMinimumScaleFactor: CGFloat = 0.7
    }
}
