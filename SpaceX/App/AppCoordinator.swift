import UIKit

protocol Coordinator: AnyObject {
    func start()
}

protocol AppCoordinating: AnyObject {
    func showSettings(from viewController: UIViewController)
    func showLaunches(for rocket: Rocket)
    func showLaunchDetail(for launchId: String)
    func popViewController()
    func dismissViewController(from viewController: UIViewController)
    func showLoading(from presenter: UIViewController)
    func hideLoading()
    func hideLoading(completion: (() -> Void)?)
}

class AppCoordinator: Coordinator {
    private static let logger = AppLogger.make("AppCoordinator")

    private let window: UIWindow
    private let appContainer: AppContainer
    let navigationController: UINavigationController
    private weak var loadingViewController: LoadingViewController?
    
    init(window: UIWindow, appContainer: AppContainer = AppContainer()) {
        self.window = window
        self.appContainer = appContainer
        self.navigationController = UINavigationController()
        
        setupNavigationController()
    }
    
    func start() {
        let rocketViewController = RocketViewController(
            rocketViewModel: appContainer.rocketViewModel,
            settingsStore: appContainer.settingsStore,
            rocketFormatter: appContainer.rocketFormatter,
            dateFormatter: appContainer.dateFormatter
        )
        rocketViewController.coordinator = self
        navigationController.pushViewController(rocketViewController, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    private func setupNavigationController() {
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backButtonAppearance = backButtonAppearance
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
    }
    
    func showSettings(from viewController: UIViewController) {
        let settingsViewController = SettingsViewController(viewModel: appContainer.makeSettingsViewModel())
        settingsViewController.coordinator = self
        settingsViewController.modalPresentationStyle = .formSheet
        viewController.present(settingsViewController, animated: true)
    }
    
    func showLaunches(for rocket: Rocket) {
        Self.logger.debug("Navigating to launches for rocket id=\(rocket.id, privacy: .public) name=\(rocket.name, privacy: .public)")
        let launchViewController = LaunchViewController(
            rocketId: rocket.id,
            rocketName: rocket.name,
            launchListViewModel: appContainer.launchListViewModel
        )
        launchViewController.coordinator = self
        
        let backButton = UIBarButtonItem()
        backButton.title = L10n.navigationBack
        backButton.tintColor = .white
        navigationController.topViewController?.navigationItem.backBarButtonItem = backButton
        
        navigationController.pushViewController(launchViewController, animated: true)
    }

    func showLaunchDetail(for launchId: String) {
        let viewModel = appContainer.makeLaunchDetailViewModel(launchId: launchId)
        let viewController = LaunchDetailViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func showLoading(from presenter: UIViewController) {
        guard loadingViewController == nil else { return }
        guard presenter.viewIfLoaded?.window != nil else {
            Self.logger.error("Skipped loading presentation because presenter is detached: \(String(describing: type(of: presenter)), privacy: .public)")
            return
        }

        let loadingViewController = LoadingViewController()
        loadingViewController.modalPresentationStyle = .overFullScreen
        Self.logger.debug("Presenting loading controller from \(String(describing: type(of: presenter)), privacy: .public)")
        presenter.present(loadingViewController, animated: false)
        self.loadingViewController = loadingViewController
    }

    func hideLoading() {
        hideLoading(completion: nil)
    }

    func hideLoading(completion: (() -> Void)?) {
        guard let loadingViewController else {
            completion?()
            return
        }

        Self.logger.debug("Dismissing loading controller")
        loadingViewController.dismiss(animated: false) { [weak self] in
            self?.loadingViewController = nil
            completion?()
        }
    }
    
    func popViewController() {
        navigationController.popViewController(animated: true)
    }
    
    func dismissViewController(from viewController: UIViewController) {
        viewController.dismiss(animated: true)
    }
    
    func updateStatusBarStyle(for viewController: UIViewController) {
        viewController.setNeedsStatusBarAppearanceUpdate()
    }
}

extension AppCoordinator: AppCoordinating {}
