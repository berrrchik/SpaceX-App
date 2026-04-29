import UIKit
import OSLog

class LaunchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "LaunchViewController"
    )
    
    let rocketId: String
    let rocketName: String
    private let launchViewModel: LaunchViewModel
    private let launchView = LaunchView()
    private var launches: [LaunchElement] = []
    private var errorMessage: String?
    private var hasRequestedInitialLoad = false
    private let paginationIndicator = UIActivityIndicatorView(style: .medium)
    weak var coordinator: AppCoordinating?
    
    init(rocketId: String, rocketName: String, launchViewModel: LaunchViewModel = LaunchViewModel()) {
        self.rocketId = rocketId
        self.rocketName = rocketName
        self.launchViewModel = launchViewModel
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
        launchView.tableView.register(LaunchCell.self, forCellReuseIdentifier: "LaunchCell")
        launchView.tableView.rowHeight = UITableView.automaticDimension
        launchView.tableView.estimatedRowHeight = 120
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

        launchViewModel.fetchInitialLaunches(rocketId: rocketId) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.launchView.hideLoadingOverlay()
                switch result {
                case .success(let launches):
                    Self.logger.debug("Initial launch data callback received. rocket id=\(self.rocketId, privacy: .public) count=\(launches.count, privacy: .public)")
                    if launches.isEmpty {
                        self.showError("Нет данных о запуске этой ракеты")
                    } else {
                        self.launches = launches
                        self.errorMessage = nil
                        self.updatePaginationFooter()
                        self.launchView.tableView.reloadData()
                    }
                case .failure:
                    Self.logger.error("Initial launch data callback failed for rocket id=\(self.rocketId, privacy: .public)")
                    self.showError("ОКАК! Что-то пошло не так, проверьте соединение")
                }
            }
        }
    }

    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        launchViewModel.loadNextPageIfNeeded(rocketId: rocketId, currentIndex: indexPath.row) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let launches):
                    self.launches = launches
                    self.updatePaginationFooter()
                    self.launchView.tableView.reloadData()
                case .failure:
                    Self.logger.error("Next launch page callback failed for rocket id=\(self.rocketId, privacy: .public)")
                    self.updatePaginationFooter()
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        Self.logger.error("Showing launches error state for rocket id=\(self.rocketId, privacy: .public): \(message, privacy: .public)")
        launchView.hideLoadingOverlay()
        updatePaginationFooter()
        errorMessage = message
        launches = []
        launchView.tableView.reloadData()
    }

    private func updatePaginationFooter() {
        let isPaginating = launchViewModel.isLoadingPage(for: rocketId) && launchViewModel.hasLoadedLaunches(for: rocketId)

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
        return errorMessage != nil ? 1 : launches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let errorMessage = errorMessage {
            return createErrorCell(with: errorMessage)
        } else {
            return createLaunchCell(for: indexPath)
        }
    }
    
    private func createErrorCell(with message: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = AppColors.clear
        cell.textLabel?.text = message
        cell.textLabel?.textColor = AppColors.textGray56
        cell.textLabel?.font = AppFonts.regular20
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
    
    private func createLaunchCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = launchView.tableView.dequeueReusableCell(withIdentifier: "LaunchCell", for: indexPath)
        guard let launchCell = cell as? LaunchCell else { return cell }
        let launch = launches[indexPath.row]
        launchCell.configure(with: launch)
        return launchCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return errorMessage != nil ? Constants.errorRowHeight : tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard errorMessage == nil else { return }
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
