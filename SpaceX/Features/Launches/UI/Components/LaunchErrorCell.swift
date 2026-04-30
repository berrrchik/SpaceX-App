import UIKit
import SnapKit

final class LaunchErrorCell: UICollectionViewCell {
    static let reuseId = "LaunchErrorCell"

    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        messageLabel.text = message
        isAccessibilityElement = true
        accessibilityLabel = message
    }

    private func setupView() {
        backgroundColor = AppColors.clear
        contentView.backgroundColor = AppColors.clear

        messageLabel.textColor = AppColors.textGray56
        messageLabel.font = AppFonts.regular20
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
}
