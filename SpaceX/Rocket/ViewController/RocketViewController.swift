import UIKit
import OSLog

class RocketViewController: UIViewController {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "RocketViewController"
    )
    
    private let rocketViewModel: RocketViewModel
    private let settingsViewModel: SettingsViewModel
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let pageControl = UIPageControl()
    private var rocketViewControllers: [RocketContentViewController] = []
    private var hasRequestedInitialData = false
    weak var coordinator: AppCoordinating?
    
    init(
        rocketViewModel: RocketViewModel = RocketViewModel(),
        settingsViewModel: SettingsViewModel
    ) {
        self.rocketViewModel = rocketViewModel
        self.settingsViewModel = settingsViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Self.logger.debug("viewDidLoad completed; waiting for hierarchy attachment before fetching rockets")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasRequestedInitialData else { return }
        hasRequestedInitialData = true

        Self.logger.debug("viewDidAppear; starting initial rocket fetch. windowAttached=\(self.view.window != nil, privacy: .public)")
        fetchData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupUI() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        
        let pageControlContainer = UIView()
        pageControlContainer.backgroundColor = AppColors.pageControlContainer
        
        view.addSubview(pageControlContainer)
        pageControlContainer.addSubview(pageControl)
        
        pageViewController.didMove(toParent: self)
        
        view.backgroundColor = AppColors.black
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        pageControl.currentPageIndicatorTintColor = AppColors.white
        pageControl.pageIndicatorTintColor = AppColors.lightGray
        pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        
        pageViewController.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControlContainer.snp.top)
        }
        
        pageControlContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(view.safeAreaInsets.bottom + Constants.pageControlContainerHeight)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.pageControlTopOffset)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    private func fetchData() {
        Self.logger.debug("Fetching rockets")
        coordinator?.showLoading(from: self)
        rocketViewModel.fetchRockets { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success:
                    Self.logger.debug("Rocket fetch succeeded with \(self.rocketViewModel.numberOfRockets, privacy: .public) rockets")
                    self.setupPages()
                case .failure:
                    Self.logger.error("Rocket fetch failed; presenting alert")
                    self.showErrorAlert()
                }

                self.coordinator?.hideLoading()
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось загрузить данные о ракетах.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupPages() {
        rocketViewControllers = (0..<rocketViewModel.numberOfRockets).compactMap { index in
            guard let rocket = rocketViewModel.rocket(at: index) else {
                return nil
            }

            let vc = RocketContentViewController(settingsViewModel: settingsViewModel)
            vc.configure(with: rocket)
            vc.coordinator = coordinator
            vc.pageIndex = index
            return vc
        }

        Self.logger.debug("Configured \(self.rocketViewControllers.count, privacy: .public) rocket pages")
        
        pageControl.numberOfPages = rocketViewControllers.count
        pageControl.isHidden = rocketViewControllers.count <= 1
        
        if let first = rocketViewControllers.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
    }
    
    @objc private func pageControlChanged(_ sender: UIPageControl) {
        let currentPage = sender.currentPage
        guard currentPage < rocketViewControllers.count else { return }
        
        let direction: UIPageViewController.NavigationDirection = currentPage > (pageViewController.viewControllers?.first as? RocketContentViewController)?.pageIndex ?? 0 ? .forward : .reverse
        pageViewController.setViewControllers([rocketViewControllers[currentPage]], direction: direction, animated: true)
    }
}

extension RocketViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? RocketContentViewController,
              let index = rocketViewControllers.firstIndex(of: currentVC),
              index > 0 else { return nil }
        return rocketViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? RocketContentViewController,
              let index = rocketViewControllers.firstIndex(of: currentVC),
              index < rocketViewControllers.count - 1 else { return nil }
        return rocketViewControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentVC = pageViewController.viewControllers?.first as? RocketContentViewController,
              let index = rocketViewControllers.firstIndex(of: currentVC) else { return }
        pageControl.currentPage = index
    }
}

private extension RocketViewController {
    enum Constants {
        static let pageControlContainerHeight: CGFloat = 70
        static let pageControlTopOffset: CGFloat = 16
    }
}
