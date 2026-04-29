import UIKit
import OSLog

class LaunchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "LaunchViewController"
    )
    
    let rocketId: String
    let rocketName: String
    private let launchListViewModel: LaunchListViewModel
    private let launchView = LaunchView()
    private var cellViewModels: [LaunchCellViewModel] = []
    private var currentState: LaunchListState = .initialLoading
    private var hasRequestedInitialLoad = false
    private let paginationIndicator = UIActivityIndicatorView(style: .medium)
    weak var coordinator: AppCoordinating?
    
    init(rocketId: String, rocketName: String, launchListViewModel: LaunchListViewModel) {
        self.rocketId = rocketId
        self.rocketName = rocketName
        self.launchListViewModel = launchListViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Self.logger.debug("viewDidLoad for rocket id=\(self.rocketId, privacy: .public) name=\(self.rocketName, privacy: .public)")
        setupViewController()
        setupTableView()
        setupBackButtonHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.title = rocketName
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasRequestedInitialLoad else { return }
        hasRequestedInitialLoad = true
        loadInitialLaunchesData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupViewController() {
        view = launchView
        launchView.backgroundColor = AppColors.black
    }
    
    private func setupTableView() {
        launchView.tableView.dataSource = self
        launchView.tableView.delegate = self
        paginationIndicator.hidesWhenStopped = true
    }
    
    private func setupBackButtonHandler() {
        launchView.onBackButtonTap = { [weak self] in
            self?.coordinator?.popViewController()
        }
    }
    
    private func loadInitialLaunchesData() {
        Self.logger.debug("Loading initial launches for rocket id=\(self.rocketId, privacy: .public)")
        launchView.showLoadingOverlay()

        launchListViewModel.loadInitialLaunches(for: rocketId) { [weak self] state in
            guard let self else { return }
            self.currentState = state
            self.handleStateUpdate(state)
        }
    }

    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        launchListViewModel.loadNextPageIfNeeded(
            for: rocketId,
            currentIndex: indexPath.row,
            totalItems: cellViewModels.count
        ) { [weak self] state in
            guard let self else { return }
            self.currentState = state
            self.handleStateUpdate(state)
        }
    }
    
    private func handleStateUpdate(_ state: LaunchListState) {
        switch state {
        case .initialLoading:
            break
            
        case .content(let viewModels):
            Self.logger.debug("Launch content state. rocket id=\(self.rocketId, privacy: .public) count=\(viewModels.count, privacy: .public)")
            launchView.hideLoadingOverlay()
            cellViewModels = viewModels
            updatePaginationFooter()
            launchView.tableView.reloadData()
            
        case .paginating(let viewModels):
            cellViewModels = viewModels
            updatePaginationFooter()
            
        case .empty:
            Self.logger.debug("Launch empty state for rocket id=\(self.rocketId, privacy: .public)")
            launchView.hideLoadingOverlay()
            cellViewModels = []
            updatePaginationFooter()
            launchView.tableView.reloadData()
            
        case .error(let message):
            Self.logger.error("Launch error state for rocket id=\(self.rocketId, privacy: .public): \(message, privacy: .public)")
            launchView.hideLoadingOverlay()
            cellViewModels = []
            updatePaginationFooter()
            launchView.tableView.reloadData()
            showErrorAlert(message)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updatePaginationFooter() {
        let isPaginating: Bool
        if case .paginating = currentState {
            isPaginating = true
        } else {
            isPaginating = false
        }

        if isPaginating {
            paginationIndicator.startAnimating()
            paginationIndicator.frame = CGRect(x: 0, y: 0, width: launchView.tableView.bounds.width, height: Constants.paginationFooterHeight)
            launchView.tableView.tableFooterView = paginationIndicator
        } else {
            paginationIndicator.stopAnimating()
            launchView.tableView.tableFooterView = UIView(frame: .zero)
        }
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentState {
        case .empty:
            return 1
        case .error:
            return 1
        default:
            return cellViewModels.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState {
        case .empty:
            return createErrorCell(with: "Нет данных о запуске этой ракеты")
        case .error(let message):
            return createErrorCell(with: message)
        default:
            return createLaunchCell(for: indexPath)
        }
    }
    
    private func createErrorCell(with message: String) -> UITableViewCell {
        let cell = launchView.tableView.dequeueReusableCell(withIdentifier: LaunchErrorCell.reuseId)
            ?? LaunchErrorCell(style: .default, reuseIdentifier: LaunchErrorCell.reuseId)
        (cell as? LaunchErrorCell)?.configure(message: message)
        return cell
    }
    
    private func createLaunchCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = launchView.tableView.dequeueReusableCell(withIdentifier: "LaunchCell", for: indexPath)
        guard let launchCell = cell as? LaunchCell else { return cell }
        let viewModel = cellViewModels[indexPath.row]
        launchCell.configure(with: viewModel)
        return launchCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch currentState {
        case .empty, .error:
            return Constants.errorRowHeight
        default:
            return tableView.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .content = currentState else { return }
        updatePaginationFooter()
        loadNextPageIfNeeded(for: indexPath)
    }
}

private extension LaunchViewController {
    enum Constants {
        static let errorRowHeight: CGFloat = 100
        static let paginationFooterHeight: CGFloat = 56
    }
}
