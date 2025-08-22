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
            make.height.equalTo(96)
        }
    }
    
    private func setupSquareStack() {
        squareStack.axis = .horizontal
        squareStack.spacing = 20
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
        for _ in 0..<4 {
            let square = UIView()
            square.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.00)
            square.layer.cornerRadius = 32
            
            let labelStack = UIStackView()
            labelStack.axis = .vertical
            labelStack.spacing = 5
            labelStack.alignment = .center
            
            let valueLabel = UILabel()
            valueLabel.textColor = .white
            valueLabel.numberOfLines = 0
            valueLabel.font = UIFont(name: "LabGrotesque-Bold", size: 16)
            
            let measureLabel = UILabel()
            measureLabel.textColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
            measureLabel.numberOfLines = 2
            measureLabel.font = UIFont(name: "LabGrotesque-Regular", size: 14)
            measureLabel.adjustsFontSizeToFitWidth = true
            measureLabel.minimumScaleFactor = 0.7
            measureLabel.lineBreakMode = .byWordWrapping
            
            labelStack.addArrangedSubview(valueLabel)
            labelStack.addArrangedSubview(measureLabel)
            
            square.addSubview(labelStack)
            labelStack.snp.makeConstraints { make in
                make.center.equalTo(square)
                make.leading.greaterThanOrEqualTo(square).offset(8)
                make.trailing.lessThanOrEqualTo(square).offset(-8)
            }
            
            square.snp.makeConstraints { make in
                make.width.height.equalTo(96)
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
