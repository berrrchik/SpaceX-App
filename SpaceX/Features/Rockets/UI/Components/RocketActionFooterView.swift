import UIKit
import SnapKit

final class RocketActionFooterView: UIView {
    let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(actionButton)

        actionButton.setTitle(L10n.rocketShowLaunches, for: .normal)
        actionButton.titleLabel?.font = AppFonts.bold18
        actionButton.tintColor = AppColors.buttonTint96
        actionButton.backgroundColor = AppColors.buttonBackgroundGray
        actionButton.layer.cornerRadius = 16

        actionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(56)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
