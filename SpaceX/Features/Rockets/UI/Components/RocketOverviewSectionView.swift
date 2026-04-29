import UIKit
import SnapKit

final class RocketOverviewSectionView: UIView {
    private let stackView = UIStackView()
    private let firstFlightValue = UILabel()
    private let countryValue = UILabel()
    private let costValue = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(firstFlight: String, country: String, cost: String) {
        firstFlightValue.text = firstFlight
        countryValue.text = country
        costValue.text = cost
    }

    private func setupView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(makeRow(title: L10n.rocketFirstFlight, valueLabel: firstFlightValue))
        stackView.addArrangedSubview(makeRow(title: L10n.rocketCountry, valueLabel: countryValue))
        stackView.addArrangedSubview(makeRow(title: L10n.rocketCostPerLaunch, valueLabel: costValue))
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
