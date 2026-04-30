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
    private var filters: [LaunchFilterItem] = []
    private var currentState: LoadableState<[LaunchCellViewModel]> = .idle
    private var hasRequestedInitialLoad = false
    private var isPaginating = false
    private var dataSource: DataSource?
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
        setupCollectionView()
        configureDataSource()
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
            isPaginating = false
            setCachedBadgeVisible(false)
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
            setCachedBadgeVisible(false)
            
        case .loaded(let viewModels, let isStale):
            Self.logger.debug("Launch content state. rocket id=\(self.rocketId, privacy: .public) count=\(viewModels.count, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            cellViewModels = viewModels
            setCachedBadgeVisible(isStale)
            applySnapshot(for: state, animating: hasRequestedInitialLoad)

        case .empty(let message):
            Self.logger.debug("Launch empty state for rocket id=\(self.rocketId, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            cellViewModels = []
            setCachedBadgeVisible(false)
            currentState = .empty(message: message)
            applySnapshot(for: currentState, animating: true)

        case .failed(let message, let cachedValue):
            Self.logger.error("Launch error state for rocket id=\(self.rocketId, privacy: .public): \(message, privacy: .public)")
            launchView.hideLoadingOverlay()
            isPaginating = false
            if let cachedValue, !cachedValue.isEmpty {
                cellViewModels = cachedValue
                setCachedBadgeVisible(true)
                currentState = .failed(message: message, cachedValue: cachedValue)
            } else {
                cellViewModels = []
                setCachedBadgeVisible(false)
                currentState = .empty(message: message)
            }
            applySnapshot(for: currentState, animating: true)
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
        let snapshot = LaunchesSnapshotBuilder.make(state: state, filters: filters)
        Self.logger.debug("Applying snapshot: \(snapshot.numberOfItems, privacy: .public) items")
        dataSource?.apply(snapshot, animatingDifferences: animating)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard case .loaded = currentState,
              let section = dataSource?.snapshot().sectionIdentifiers[indexPath.section],
              section == .launches else { return }
        loadNextPageIfNeeded(for: indexPath)
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
