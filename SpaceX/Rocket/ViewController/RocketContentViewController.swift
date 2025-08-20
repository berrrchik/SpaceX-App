import UIKit

class RocketContentViewController: UIViewController {
    
    var pageIndex: Int = 0
    
    let rocketView: RocketView
    private var previousStatusBarHidden = false
    private var currentRocket: RocketElement?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.rocketView = RocketView(viewModel: SettingsViewModel())
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        self.rocketView = RocketView(viewModel: SettingsViewModel())
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettingsButtonAction()
        setupShowLaunchesButtonAction()
    }
    
    override func loadView() {
        view = rocketView
        rocketView.scrollView.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rocketView.adjustScrollViewInsets(safeAreaInsets: view.safeAreaInsets)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return shouldHideStatusBar
    }
    
    private var shouldHideStatusBar: Bool {
        let frame = rocketView.textContainer.convert(rocketView.textContainer.bounds, to: nil)
        return frame.minY < view.safeAreaInsets.top
    }
    
    func configure(with rocket: RocketElement) {
        let randomImageURLString = rocket.flickrImages.randomElement()
        let imageURL: URL? = randomImageURLString.flatMap { URL(string: $0) }
        rocketView.configure(with: rocket, imageURL: imageURL)
        self.currentRocket = rocket
    }
    
    private func setupSettingsButtonAction() {
        rocketView.settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func settingsButtonTapped() {
        let settingsViewController = SettingsViewController()
        settingsViewController.modalPresentationStyle = .formSheet
        present(settingsViewController, animated: true, completion: nil)
    }
    
    private func setupShowLaunchesButtonAction() {
        rocketView.showLaunchesButton.addTarget(self, action: #selector(showLaunchesButtonTapped), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func showLaunchesButtonTapped() {
        guard let rocket = currentRocket else { return }
        let launchViewController = LaunchViewController(rocketId: rocket.id, rocketName: rocket.name)
        self.navigationController?.navigationBar.tintColor = .white
        navigationController?.pushViewController(launchViewController, animated: true)
    }
}

extension RocketContentViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shouldHide = self.shouldHideStatusBar
        if self.previousStatusBarHidden != shouldHide {
            UIView.animate(withDuration: 0.2) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
            self.previousStatusBarHidden = shouldHide
        }
    }
}
