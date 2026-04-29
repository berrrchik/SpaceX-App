import UIKit
import SnapKit

final class RocketHeaderView: UIView {
    let titleLabel = UILabel()
    let settingsButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setupView() {
        addSubview(titleLabel)
        addSubview(settingsButton)

        titleLabel.textColor = AppColors.white
        titleLabel.numberOfLines = 0
        titleLabel.font = AppFonts.bold32

        settingsButton.setImage(
            UIImage(systemName: "gearshape", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32))?.withTintColor(AppColors.white),
            for: .normal
        )
        settingsButton.tintColor = AppColors.white

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(settingsButton.snp.leading).offset(-16)
            make.bottom.equalToSuperview()
        }

        settingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(32)
        }
    }
}
