import UIKit

class LaunchViewController: UIViewController {
    
    let launchView = LaunchView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        launchView.backgroundColor = .systemPink
    }
    
    override func loadView() {
        view = launchView
    }
}
