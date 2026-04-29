import UIKit

class SettingsViewController: UIViewController {
    
    private let settingsView: SettingsView
    private let viewModel: SettingsViewModel
    weak var coordinator: AppCoordinating?
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self.settingsView = SettingsView(toggleStates: viewModel.getToggleStates())
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButtonAction()
        bindToggles()
    }
    
    override func loadView() {
        view = settingsView
    }
    
    private func setupCloseButtonAction() {
        settingsView.closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    private func bindToggles() {
        settingsView.onToggleChanged = { [weak self] index, _ in
            self?.viewModel.toggleState(at: index)
        }
    }
    
    @objc private func closeButtonTapped() {
        viewModel.saveSettings()
        coordinator?.dismissViewController(from: self)
    }
}
