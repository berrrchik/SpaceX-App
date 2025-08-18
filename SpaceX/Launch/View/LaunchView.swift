import UIKit
import SnapKit

final class LaunchView: UIView {
    
    var launches: [LaunchElement]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var errorMessage: String? {
        didSet {
            tableView.reloadData()
        }
    }
    
    let tableView = UITableView()
    
    var onBackButtonTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(tableView)
        setupTableView()
    }
    
    private func setupTableView() {
        addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(LaunchCell.self, forCellReuseIdentifier: "LaunchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(40)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview()
        }
    }
    
    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }
}
