import UIKit

class SettingsViewController: UIViewController {
    
    private let settingsView: SettingsView
    private let viewModel = SettingsViewModel()
    weak var coordinator: AppCoordinator?
    
    init() {
        self.settingsView = SettingsView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButtonAction()
    }
    
    override func loadView() {
        view = settingsView
    }
    
    private func setupCloseButtonAction() {
        settingsView.closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func closeButtonTapped() {
        settingsView.saveSettings()
        coordinator?.dismissViewController(from: self)
    }
}
