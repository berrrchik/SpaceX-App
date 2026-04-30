import UIKit
import SnapKit

final class LaunchFilterCell: UICollectionViewCell {
    static let reuseId = "LaunchFilterCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: LaunchFilterItem) {
        titleLabel.text = item.title
        contentView.backgroundColor = item.isSelected ? AppColors.white : AppColors.cardGray
        titleLabel.textColor = item.isSelected ? AppColors.activeBlack07 : AppColors.white

        isAccessibilityElement = true
        accessibilityLabel = item.title
        accessibilityTraits = item.isSelected ? [.button, .selected] : [.button]
        accessibilityIdentifier = "filterChip_\(item.id)"
    }

    private func setupView() {
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)

        titleLabel.font = AppFonts.regular14
        titleLabel.textAlignment = .center

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }
}
