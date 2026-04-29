import UIKit
import SnapKit

final class LaunchView: UIView {
    
    let tableView = UITableView()
    private let loadingOverlayView = LoadingView()
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
        setupLoadingOverlay()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AppColors.clear
        tableView.separatorStyle = .none
        tableView.register(LaunchCell.self, forCellReuseIdentifier: "LaunchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(Constants.tableTopOffset)
            make.leading.equalToSuperview().offset(Constants.horizontalMargin)
            make.trailing.equalToSuperview().inset(Constants.horizontalMargin)
            make.bottom.equalToSuperview()
        }
    }

    private func setupLoadingOverlay() {
        addSubview(loadingOverlayView)
        loadingOverlayView.isHidden = true
        loadingOverlayView.isUserInteractionEnabled = false

        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }

    func showLoadingOverlay() {
        loadingOverlayView.isHidden = false
    }

    func hideLoadingOverlay() {
        loadingOverlayView.isHidden = true
        loadingOverlayView.stopRotationAnimation()
    }
    
    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }
}

private extension LaunchView {
    enum Constants {
        static let tableTopOffset: CGFloat = 40
        static let horizontalMargin: CGFloat = 32
        static let estimatedRowHeight: CGFloat = 120
    }
}
