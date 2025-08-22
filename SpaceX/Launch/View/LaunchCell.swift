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
        contentView.backgroundColor = .black
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
        cardView.layer.cornerRadius = 24
        cardView.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.00)
        cardView.clipsToBounds = true
        
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    private func setupNameLabel() {
        nameLabel.numberOfLines = 0
        nameLabel.font = UIFont(name: "LabGrotesque-Regular", size: 20)
        nameLabel.textColor = .white
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.lessThanOrEqualTo(statusImageView.snp.leading).offset(-24)
        }
    }
    
    private func setupDateLabel() {
        dateLabel.numberOfLines = 1
        dateLabel.font = UIFont(name: "LabGrotesque-Regular", size: 16)
        dateLabel.textColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(24)
            make.trailing.lessThanOrEqualTo(statusImageView.snp.leading).offset(-24)
            make.bottom.lessThanOrEqualToSuperview().offset(-24)
        }
    }
    
    private func setupStatusImageView() {
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(32)
            make.width.height.equalTo(32)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        dateLabel.text = nil
        statusImageView.image = nil
    }
}
