import UIKit
import SnapKit

final class RocketMetricsCarouselView: UIView {
    private let squareView = SquareView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(squareView)
        squareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(96)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [(value: String, unit: String, label: String)]) {
        squareView.configure(with: items)
    }
}
