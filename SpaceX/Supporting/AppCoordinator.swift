import UIKit
import OSLog

protocol Coordinator: AnyObject {
    func start()
}

protocol AppCoordinating: AnyObject {
    func showSettings(from viewController: UIViewController)
    func showLaunches(for rocket: RocketElement)
    func popViewController()
    func dismissViewController(from viewController: UIViewController)
    func showLoading(from presenter: UIViewController)
    func hideLoading()
}

class AppCoordinator: Coordinator {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "AppCoordinator"
    )

    private let window: UIWindow
    let navigationController: UINavigationController
    private let rocketViewModel: RocketViewModel
    private let launchViewModel: LaunchViewModel
    private let settingsViewModel: SettingsViewModel
    private weak var loadingViewController: LoadingViewController?
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.rocketViewModel = RocketViewModel()
        self.launchViewModel = LaunchViewModel()
        self.settingsViewModel = SettingsViewModel()
        
        setupNavigationController()
    }
    
    func start() {
        let rocketViewController = RocketViewController(
            rocketViewModel: rocketViewModel,
            settingsViewModel: settingsViewModel
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
        let settingsViewController = SettingsViewController(viewModel: settingsViewModel)
        settingsViewController.coordinator = self
        settingsViewController.modalPresentationStyle = .formSheet
        viewController.present(settingsViewController, animated: true)
    }
    
    func showLaunches(for rocket: RocketElement) {
        Self.logger.debug("Navigating to launches for rocket id=\(rocket.id, privacy: .public) name=\(rocket.name, privacy: .public)")
        let launchViewController = LaunchViewController(rocketId: rocket.id, rocketName: rocket.name, launchViewModel: launchViewModel)
        launchViewController.coordinator = self
        
        let backButton = UIBarButtonItem()
        backButton.title = "Назад"
        backButton.tintColor = .white
        navigationController.topViewController?.navigationItem.backBarButtonItem = backButton
        
        navigationController.pushViewController(launchViewController, animated: true)
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
        Self.logger.debug("Dismissing loading controller")
        loadingViewController?.dismiss(animated: false)
        loadingViewController = nil
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
