import UIKit

class LoadingViewController: UIViewController {
    
    private let loadingView = LoadingView()
    var onCompletion: (() -> Void)?
    
    override func loadView() {
        view = loadingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func stopAnimationAndDismiss() {
        loadingView.stopRotationAnimation()
        dismiss(animated: false) {
            self.onCompletion?()
        }
    }
}
