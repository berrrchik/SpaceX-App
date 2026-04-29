import UIKit

final class LaunchErrorCell: UITableViewCell {
    static let reuseId = "LaunchErrorCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = AppColors.clear
        contentView.backgroundColor = AppColors.clear

        textLabel?.textColor = AppColors.textGray56
        textLabel?.font = AppFonts.regular20
        textLabel?.textAlignment = .center
        textLabel?.numberOfLines = 0
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        textLabel?.text = message
    }
}
