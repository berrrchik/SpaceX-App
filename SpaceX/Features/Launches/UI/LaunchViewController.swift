import UIKit

final class LaunchViewController: UIViewController, UICollectionViewDelegate {
    private static let logger = AppLogger.make("LaunchViewController")
    private static let footerKind = UICollectionView.elementKindSectionFooter
    private typealias DataSource = UICollectionViewDiffableDataSource<LaunchesSection, LaunchesItem>
    
    let rocketId: String
    let rocketName: String
    private let launchListViewModel: LaunchListViewModel
    private let launchView = LaunchView()
    private var cellViewModels: [LaunchCellViewModel] = []
    private var query = LaunchQuery()
    private var currentState: LoadableState<[LaunchCellViewModel]> = .idle
    private var hasRequestedInitialLoad = false
    private var isPaginating = false
    private var dataSource: DataSource?
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
        setupCollectionView()
        configureDataSource()
        setupControlButtons()
        configureDropdownMenus()
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
    
    private func setupCollectionView() {
        launchView.collectionView.setCollectionViewLayout(
            LaunchView.makeLayout(sectionProvider: { [weak self] sectionIndex in
                guard let sections = self?.dataSource?.snapshot().sectionIdentifiers,
                      sectionIndex >= 0,
                      sectionIndex < sections.count else { return nil }
                return sections[sectionIndex]
            }),
            animated: false
        )
        launchView.collectionView.delegate = self
        launchView.collectionView.register(
            PaginationFooterView.self,
            forSupplementaryViewOfKind: Self.footerKind,
            withReuseIdentifier: PaginationFooterView.reuseId
        )
    }

    private func setupControlButtons() {
        [launchView.statusButton, launchView.yearButton, launchView.sortButton].forEach {
            $0.setTitleColor(AppColors.white, for: .normal)
            $0.titleLabel?.font = AppFonts.bold18
            $0.showsMenuAsPrimaryAction = true
        }
        launchView.sortButton.showsMenuAsPrimaryAction = false
        launchView.sortButton.addTarget(self, action: #selector(toggleSortOrder), for: .touchUpInside)
        updateSortButtonTitle()
    }

    private func configureDropdownMenus() {
        launchView.statusButton.setTitle(statusTitle(for: query.statusFilter) + " ▾", for: .normal)
        let statusActions = [
            UIAction(title: L10n.launchesFilterAll, state: query.statusFilter == .all ? .on : .off) { [weak self] _ in self?.setStatus(.all) },
            UIAction(title: L10n.launchesFilterSuccessful, state: query.statusFilter == .successful ? .on : .off) { [weak self] _ in self?.setStatus(.successful) },
            UIAction(title: L10n.launchesFilterFailed, state: query.statusFilter == .failed ? .on : .off) { [weak self] _ in self?.setStatus(.failed) },
            UIAction(title: L10n.launchesFilterUpcoming, state: query.statusFilter == .upcoming ? .on : .off) { [weak self] _ in self?.setStatus(.upcoming) }
        ]
        launchView.statusButton.menu = UIMenu(children: statusActions)

        launchView.yearButton.setTitle(yearTitle() + " ▾", for: .normal)
        let resetYear = UIAction(title: L10n.launchesYearDropdown, state: query.year == nil ? .on : .off) { [weak self] _ in
            self?.setYear(nil)
        }
        let yearActions = launchListViewModel.availableYears().map { year in
            UIAction(title: String(year), state: query.year == year ? .on : .off) { [weak self] _ in
                self?.setYear(year)
            }
        }
        launchView.yearButton.menu = UIMenu(children: [resetYear] + yearActions)
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
            isPaginating = false
            applySnapshot(for: state, animating: false)
        case .loading:
            let isInitialLoading = cellViewModels.isEmpty
            isPaginating = !isInitialLoading
            if isInitialLoading {
                launchView.showLoadingOverlay()
                applySnapshot(for: state, animating: false)
            } else {
                launchView.hideLoadingOverlay()
                DispatchQueue.main.async { [weak self] in
                    self?.launchView.collectionView.reloadData()
                }
            }
            
        case .loaded(let viewModels, let isStale):
            Self.logger.debug("Launch content state. rocket id=\(self.rocketId, privacy: .public) count=\(viewModels.count, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            cellViewModels = viewModels
            _ = isStale
            configureDropdownMenus()
            applySnapshot(for: state, animating: hasRequestedInitialLoad)

        case .empty(let message):
            Self.logger.debug("Launch empty state for rocket id=\(self.rocketId, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            cellViewModels = []
            currentState = .empty(message: message)
            configureDropdownMenus()
            applySnapshot(for: currentState, animating: true)

        case .failed(let message, let cachedValue):
            Self.logger.error("Launch error state for rocket id=\(self.rocketId, privacy: .public): \(message, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            if let cachedValue, !cachedValue.isEmpty {
                cellViewModels = cachedValue
                currentState = .failed(message: message, cachedValue: cachedValue)
            } else {
                cellViewModels = []
                currentState = .empty(message: message)
            }
            configureDropdownMenus()
            applySnapshot(for: currentState, animating: true)
            showErrorAlert(message)
        }
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

    private func configureDataSource() {
        let launchCellRegistration = UICollectionView.CellRegistration<LaunchCell, LaunchCellViewModel> { cell, _, vm in
            cell.configure(with: vm)
        }
        let filterCellRegistration = UICollectionView.CellRegistration<LaunchFilterCell, LaunchFilterItem> { cell, _, item in
            cell.configure(with: item)
        }
        let messageCellRegistration = UICollectionView.CellRegistration<LaunchErrorCell, String> { cell, _, message in
            cell.configure(message: message)
        }

        dataSource = DataSource(collectionView: launchView.collectionView) { collectionView, indexPath, item in
            switch item {
            case .launch(let vm):
                return collectionView.dequeueConfiguredReusableCell(using: launchCellRegistration, for: indexPath, item: vm)
            case .filter(let filterItem):
                return collectionView.dequeueConfiguredReusableCell(using: filterCellRegistration, for: indexPath, item: filterItem)
            case .message(let text):
                return collectionView.dequeueConfiguredReusableCell(using: messageCellRegistration, for: indexPath, item: text)
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == Self.footerKind,
                  let self,
                  let section = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
                  section == .launches else { return nil }

            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PaginationFooterView.reuseId,
                for: indexPath
            )
            guard let footer = view as? PaginationFooterView else { return view }
            footer.configure(isVisible: self.isPaginating)
            return footer
        }
    }

    private func applySnapshot(for state: LoadableState<[LaunchCellViewModel]>, animating: Bool) {
        let snapshot = LaunchesSnapshotBuilder.make(state: state, filters: [])
        Self.logger.debug("Applying snapshot: \(snapshot.numberOfItems, privacy: .public) items")
        dataSource?.apply(snapshot, animatingDifferences: animating)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard case .loaded = currentState,
              let section = dataSource?.snapshot().sectionIdentifiers[indexPath.section],
              section == .launches else { return }
        loadNextPageIfNeeded(for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        guard case .launch(let viewModel) = item else { return }
        coordinator?.showLaunchDetail(for: viewModel.id)
    }

    private func applyCurrentQuery() {
        launchListViewModel.applyQuery(query) { [weak self] state in
            guard let self else { return }
            self.currentState = state
            self.handleStateUpdate(state)
        }
    }

    private func setStatus(_ status: LaunchStatusFilter) {
        query.statusFilter = status
        configureDropdownMenus()
        applyCurrentQuery()
    }

    private func setYear(_ year: Int?) {
        query.year = year
        configureDropdownMenus()
        applyCurrentQuery()
    }

    @objc private func toggleSortOrder() {
        query.sortOrder = query.sortOrder == .newestFirst ? .oldestFirst : .newestFirst
        updateSortButtonTitle()
        applyCurrentQuery()
    }

    private func updateSortButtonTitle() {
        launchView.sortButton.setTitle(query.sortOrder == .newestFirst ? "↓" : "↑", for: .normal)
    }

    private func statusTitle(for status: LaunchStatusFilter) -> String {
        switch status {
        case .all: return L10n.launchesFilterAll
        case .successful: return L10n.launchesFilterSuccessful
        case .failed: return L10n.launchesFilterFailed
        case .upcoming: return L10n.launchesFilterUpcoming
        }
    }

    private func yearTitle() -> String {
        if let year = query.year {
            return String(year)
        }
        return L10n.launchesYearDropdown
    }
}

private final class PaginationFooterView: UICollectionReusableView {
    static let reuseId = "PaginationFooterView"
    private let indicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        indicator.hidesWhenStopped = true
        indicator.center = center
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isVisible: Bool) {
        if isVisible {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
    }
}
