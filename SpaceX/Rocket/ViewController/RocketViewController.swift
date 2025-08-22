import UIKit

class RocketViewController: UIViewController {
    
    private let rocketViewModel: RocketViewModel
    private let launchViewModel = LaunchViewModel()
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let pageControl = UIPageControl()
    private let pageControlContainer = UIView()
    private var rocketViewControllers: [RocketContentViewController] = []
    
    init(rocketViewModel: RocketViewModel = RocketViewModel()) {
        self.rocketViewModel = rocketViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
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
        rocketViewModel.fetchRockets { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.setupPages()
                    self?.loadLaunches()
                case .failure:
                    print("Error fetching rockets")
                }
            }
        }
    }
    
    private func loadLaunches() {
        launchViewModel.loadAllLaunches { result in
            switch result {
            case .success:
                print("Запуски загружены")
            case .failure(let error):
                print("Ошибка загрузки запусков: \(error)")
            }
        }
    }
    
    private func setupPages() {
        rocketViewControllers = (0..<rocketViewModel.numberOfRockets).map { index in
            guard let rocket = rocketViewModel.rocket(at: index) else {
                return RocketContentViewController()
            }
            let vc = RocketContentViewController()
            vc.configure(with: rocket)
            return vc
        }
        
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

extension RocketViewController: UIPageViewControllerDataSource {
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
}

extension RocketViewController: UIPageViewControllerDelegate {
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
