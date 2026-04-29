import UIKit

class RocketContentViewController: UIViewController {
    
    var pageIndex: Int = 0
    weak var coordinator: AppCoordinating?
    
    let rocketView: RocketView
    private var previousStatusBarHidden = false
    private var currentRocket: RocketElement?
    
    init(settingsViewModel: SettingsViewModel) {
        self.rocketView = RocketView(viewModel: settingsViewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        coordinator?.showSettings(from: self)
    }
    
    private func setupShowLaunchesButtonAction() {
        rocketView.showLaunchesButton.addTarget(self, action: #selector(showLaunchesButtonTapped), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func showLaunchesButtonTapped() {
        guard let rocket = currentRocket else { return }
        coordinator?.showLaunches(for: rocket)
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
