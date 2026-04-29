import UIKit
import SnapKit

final class RocketStageSectionView: UIView {
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let enginesValue = UILabel()
    private let fuelValue = UILabel()
    private let burnTimeValue = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(engines: String, fuel: String, burnTime: String) {
        enginesValue.text = engines
        fuelValue.text = fuel
        burnTimeValue.text = burnTime
    }

    private func setupView() {
        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.textColor = AppColors.white
        titleLabel.font = AppFonts.bold16

        stackView.axis = .vertical
        stackView.spacing = 16

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        stackView.addArrangedSubview(makeRow(title: L10n.rocketEnginesCount, valueLabel: enginesValue))
        stackView.addArrangedSubview(makeRow(title: L10n.rocketFuelAmount, valueLabel: fuelValue))
        stackView.addArrangedSubview(makeRow(title: L10n.rocketBurnTime, valueLabel: burnTimeValue))
    }

    private func makeRow(title: String, valueLabel: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = AppColors.labelGray79
        titleLabel.font = AppFonts.regular16

        valueLabel.textColor = AppColors.white
        valueLabel.font = AppFonts.medium16
        valueLabel.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fill
        row.spacing = 20
        return row
    }
}
