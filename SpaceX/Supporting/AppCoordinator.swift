import UIKit

protocol Coordinator: AnyObject {
    func start()
}

class AppCoordinator: Coordinator {
    private let window: UIWindow
    let navigationController: UINavigationController
    private let rocketViewModel: RocketViewModel
    private let launchViewModel: LaunchViewModel
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.rocketViewModel = RocketViewModel()
        self.launchViewModel = LaunchViewModel()
        
        setupNavigationController()
    }
    
    func start() {
        let rocketViewController = RocketViewController(rocketViewModel: rocketViewModel)
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
        let settingsViewController = SettingsViewController()
        settingsViewController.coordinator = self
        settingsViewController.modalPresentationStyle = .formSheet
        viewController.present(settingsViewController, animated: true)
    }
    
    func showLaunches(for rocket: RocketElement) {
        let launchViewController = LaunchViewController(rocketId: rocket.id, rocketName: rocket.name, launchViewModel: launchViewModel)
        launchViewController.coordinator = self
        
        let backButton = UIBarButtonItem()
        backButton.title = "Назад"
        backButton.tintColor = .white
        navigationController.topViewController?.navigationItem.backBarButtonItem = backButton
        
        navigationController.pushViewController(launchViewController, animated: true)
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
