import UIKit

protocol Coordinator: AnyObject {
    func start()
}

class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: UINavigationController
    private let rocketViewModel: RocketViewModel
    private let launchViewModel: LaunchViewModel
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.rocketViewModel = RocketViewModel()
        self.launchViewModel = LaunchViewModel()
    }
    
    func start() {
        let rocketViewController = RocketViewController(rocketViewModel: rocketViewModel)
        rocketViewController.coordinator = self
        navigationController.pushViewController(rocketViewController, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func showSettings(from viewController: UIViewController) {
        let settingsViewController = SettingsViewController()
        settingsViewController.coordinator = self
        settingsViewController.modalPresentationStyle = .formSheet
        viewController.present(settingsViewController, animated: true, completion: nil)
    }
    
    func showLaunches(for rocket: RocketElement) {
        let launchViewController = LaunchViewController(rocketId: rocket.id, rocketName: rocket.name, launchViewModel: launchViewModel)
        launchViewController.coordinator = self
        navigationController.navigationBar.tintColor = .white
        navigationController.pushViewController(launchViewController, animated: true)
    }
    
    func popViewController() {
        navigationController.popViewController(animated: true)
    }
    
    func dismissViewController(from viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
