import UIKit
import SnapKit

final class LaunchCell: UITableViewCell {
    
    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with launch: LaunchElement) {
        nameLabel.text = launch.name
        dateLabel.text = launch.getDateUTC
        
        if let success = launch.success {
            statusImageView.image = UIImage(named: success ? "LaunchSuccess" : "LaunchFail")
        } else {
            statusImageView.image = UIImage(named: "unknown")
        }
        layoutIfNeeded()
    }
    
    private func setupView() {
        contentView.backgroundColor = AppColors.black
        setupCardView()
        setupNameLabel()
        setupDateLabel()
        setupStatusImageView()
    }
    
    private func setupCardView() {
        contentView.addSubview(cardView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(dateLabel)
        cardView.addSubview(statusImageView)
        cardView.layer.cornerRadius = Constants.cardCornerRadius
        cardView.backgroundColor = AppColors.cardGray
        cardView.clipsToBounds = true
        
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.cardVerticalMargin)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Constants.cardVerticalMargin)
        }
    }
    
    private func setupNameLabel() {
        nameLabel.numberOfLines = 0
        nameLabel.font = AppFonts.regular20
        nameLabel.textColor = AppColors.white
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.labelTopMargin)
            make.leading.equalToSuperview().offset(Constants.labelHorizontalMargin)
            make.trailing.lessThanOrEqualTo(statusImageView.snp.leading).offset(-Constants.labelHorizontalMargin)
        }
    }
    
    private func setupDateLabel() {
        dateLabel.numberOfLines = 1
        dateLabel.font = AppFonts.regular16
        dateLabel.textColor = AppColors.textGray56
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(Constants.dateLabelTopOffset)
            make.leading.equalToSuperview().offset(Constants.labelHorizontalMargin)
            make.trailing.lessThanOrEqualTo(statusImageView.snp.leading).offset(-Constants.labelHorizontalMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-Constants.labelBottomMargin)
        }
    }
    
    private func setupStatusImageView() {
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(Constants.statusImageTrailingMargin)
            make.width.height.equalTo(Constants.statusImageSize)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        dateLabel.text = nil
        statusImageView.image = nil
    }
}

private extension LaunchCell {
    enum Constants {
        static let cardCornerRadius: CGFloat = 24
        static let cardVerticalMargin: CGFloat = 8
        static let labelTopMargin: CGFloat = 24
        static let labelHorizontalMargin: CGFloat = 24
        static let dateLabelTopOffset: CGFloat = 4
        static let labelBottomMargin: CGFloat = 24
        static let statusImageTrailingMargin: CGFloat = 32
        static let statusImageSize: CGFloat = 32
    }
}
