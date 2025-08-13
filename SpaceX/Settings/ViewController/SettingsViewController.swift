import UIKit

class SettingsViewController: UIViewController {
    
    let settingsView = SettingsView()
    
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
        dismiss(animated: true, completion: nil)
    }
}
