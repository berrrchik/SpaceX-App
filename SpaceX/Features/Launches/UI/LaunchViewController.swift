import UIKit
class LaunchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let logger = AppLogger.make("LaunchViewController")
    
    let rocketId: String
    let rocketName: String
    private let launchListViewModel: LaunchListViewModel
    private let launchView = LaunchView()
    private var cellViewModels: [LaunchCellViewModel] = []
    private var currentState: LoadableState<[LaunchCellViewModel]> = .idle
    private var hasRequestedInitialLoad = false
    private let paginationIndicator = UIActivityIndicatorView(style: .medium)
    private let cachedBadgeLabel = UILabel()
    private lazy var cachedBadgeItem = UIBarButtonItem(customView: cachedBadgeLabel)
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
        setupCachedBadge()
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

    private func setupCachedBadge() {
        cachedBadgeLabel.text = L10n.launchesCachedBadge
        cachedBadgeLabel.font = AppFonts.bold14
        cachedBadgeLabel.textColor = AppColors.white
        cachedBadgeLabel.backgroundColor = AppColors.darkGray.withAlphaComponent(0.8)
        cachedBadgeLabel.layer.cornerRadius = 8
        cachedBadgeLabel.layer.masksToBounds = true
        cachedBadgeLabel.textAlignment = .center
        cachedBadgeLabel.frame = CGRect(x: 0, y: 0, width: 64, height: 24)
        cachedBadgeLabel.accessibilityLabel = L10n.launchesStaleBanner
        navigationItem.rightBarButtonItem = nil
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
    
    private func handleStateUpdate(_ state: LoadableState<[LaunchCellViewModel]>) {
        switch state {
        case .idle:
            launchView.hideLoadingOverlay()
            setCachedBadgeVisible(false)
        case .loading:
            let isInitialLoading = cellViewModels.isEmpty
            if isInitialLoading {
                launchView.showLoadingOverlay()
            } else {
                launchView.hideLoadingOverlay()
            }
            setCachedBadgeVisible(false)
            
        case .loaded(let viewModels, let isStale):
            Self.logger.debug("Launch content state. rocket id=\(self.rocketId, privacy: .public) count=\(viewModels.count, privacy: .public)")
            launchView.hideLoadingOverlay()
            cellViewModels = viewModels
            setCachedBadgeVisible(isStale)
            updatePaginationFooter()
            launchView.tableView.reloadData()

        case .empty(let message):
            Self.logger.debug("Launch empty state for rocket id=\(self.rocketId, privacy: .public)")
            launchView.hideLoadingOverlay()
            cellViewModels = []
            setCachedBadgeVisible(false)
            currentState = .empty(message: message)
            updatePaginationFooter()
            launchView.tableView.reloadData()

        case .failed(let message, let cachedValue):
            Self.logger.error("Launch error state for rocket id=\(self.rocketId, privacy: .public): \(message, privacy: .public)")
            launchView.hideLoadingOverlay()
            if let cachedValue, !cachedValue.isEmpty {
                cellViewModels = cachedValue
                setCachedBadgeVisible(true)
            } else {
                cellViewModels = []
                setCachedBadgeVisible(false)
                currentState = .empty(message: message)
            }
            updatePaginationFooter()
            launchView.tableView.reloadData()
            showErrorAlert(message)
        }
    }

    private func setCachedBadgeVisible(_ isVisible: Bool) {
        navigationItem.rightBarButtonItem = isVisible ? cachedBadgeItem : nil
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: L10n.alertErrorTitle,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.alertOk, style: .default))
        present(alert, animated: true)
    }

    private func updatePaginationFooter() {
        let isPaginating: Bool
        if case .loading = currentState, !cellViewModels.isEmpty {
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
        default:
            return cellViewModels.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState {
        case .empty(let message):
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
        case .empty:
            return Constants.errorRowHeight
        default:
            return tableView.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .loaded = currentState else { return }
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
