import UIKit

class RocketContentViewController: UIViewController {
    
    var pageIndex: Int = 0
    weak var coordinator: AppCoordinating?
    
    let rocketView: RocketView
    private var previousStatusBarHidden = false
    private var currentRocket: Rocket?
    
    init() {
        self.rocketView = RocketView()
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
        return false
    }
    
    func configure(with displayModel: RocketDisplayModel, rocket: Rocket) {
        rocketView.configure(with: displayModel)
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
        let shouldHide = false
        if previousStatusBarHidden != shouldHide {
            setNeedsStatusBarAppearanceUpdate()
            previousStatusBarHidden = shouldHide
        }
    }
}
