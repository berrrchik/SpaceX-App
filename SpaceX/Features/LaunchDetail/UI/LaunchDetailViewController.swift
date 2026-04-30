import UIKit

final class LaunchDetailViewController: UIViewController {
    private let viewModel: LaunchDetailViewModel
    private let contentView = LaunchDetailView()

    weak var coordinator: AppCoordinating?

    init(viewModel: LaunchDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = contentView
        title = L10n.launchDetailTitle

        contentView.onOpenURL = { url in
            UIApplication.shared.open(url)
        }

        viewModel.onStateChange = { [weak self] state in
            self?.handle(state: state)
        }
        viewModel.load()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func handle(state: LoadableState<LaunchDetail>) {
        switch state {
        case .idle:
            contentView.hideLoadingOverlay()
        case .loading:
            contentView.showLoadingOverlay()
        case .loaded(let detail, _):
            contentView.hideLoadingOverlay()
            contentView.render(detail: detail)
        case .failed(let message, _):
            contentView.hideLoadingOverlay()
            let alert = UIAlertController(title: L10n.alertErrorTitle, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.alertOk, style: .default))
            present(alert, animated: true)
        case .empty:
            contentView.hideLoadingOverlay()
        }
    }
}
