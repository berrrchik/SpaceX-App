import UIKit
import SnapKit

final class LaunchErrorCell: UICollectionViewCell {
    static let reuseId = "LaunchErrorCell"

    private let unknownImageView = UIImageView()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String, showUnknownImage: Bool = false) {
        messageLabel.text = message
        unknownImageView.isHidden = !showUnknownImage
        isAccessibilityElement = true
        accessibilityLabel = message
    }

    private func setupView() {
        backgroundColor = AppColors.clear
        contentView.backgroundColor = AppColors.clear

        unknownImageView.contentMode = .scaleAspectFit
        unknownImageView.image = UIImage(named: "unknown")
        unknownImageView.isHidden = true

        messageLabel.textColor = AppColors.textGray56
        messageLabel.font = AppFonts.regular20
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        contentView.addSubview(unknownImageView)
        contentView.addSubview(messageLabel)
        unknownImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(96)
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(unknownImageView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }
}
