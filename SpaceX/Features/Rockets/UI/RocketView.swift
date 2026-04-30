import UIKit
import SnapKit
import Kingfisher

final class RocketView: UIView {
    let scrollView = UIScrollView()

    private let heroContainer = UIView()
    private let heroImageView = UIImageView()
    private let contentBackgroundView = UIView()
    private let contentView = UIView()

    private let headerView = RocketHeaderView()
    private let metricsView = RocketMetricsCarouselView()
    private let overviewView = RocketOverviewSectionView()
    private let firstStageView = RocketStageSectionView(title: L10n.rocketFirstStage)
    private let secondStageView = RocketStageSectionView(title: L10n.rocketSecondStage)
    private let footerView = RocketActionFooterView()

    var settingsButton: UIButton { headerView.settingsButton }
    var showLaunchesButton: UIButton { footerView.actionButton }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with displayModel: RocketDisplayModel) {
        if let imageURL = sanitizedURL(displayModel.imageURL) {
            heroImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "SomethingWentWrong"),
                options: [
                    .transition(.fade(Constants.imageFadeDuration)),
                    .cacheOriginalImage
                ]
            )
        } else {
            heroImageView.image = UIImage(named: "SomethingWentWrong")
        }

        headerView.configure(title: displayModel.name)

        metricsView.configure(items: [
            (value: displayModel.heightValue, unit: displayModel.heightUnit, label: L10n.settingsHeight),
            (value: displayModel.diameterValue, unit: displayModel.diameterUnit, label: L10n.settingsDiameter),
            (value: displayModel.massValue, unit: displayModel.massUnit, label: L10n.settingsMass),
            (value: displayModel.payloadWeightValue, unit: displayModel.payloadWeightUnit, label: L10n.settingsPayload)
        ])

        overviewView.configure(
            firstFlight: displayModel.firstFlightDate,
            country: displayModel.country,
            cost: displayModel.costPerLaunch
        )

        firstStageView.configure(
            engines: displayModel.firstStageEngines,
            fuel: displayModel.firstStageFuelTons,
            burnTime: displayModel.firstStageBurnTime
        )

        secondStageView.configure(
            engines: displayModel.secondStageEngines,
            fuel: displayModel.secondStageFuelTons,
            burnTime: displayModel.secondStageBurnTime
        )
    }

    private func sanitizedURL(_ url: URL?) -> URL? {
        guard let url else { return nil }
        if url.scheme?.lowercased() == "https" {
            return url
        }
        if url.scheme?.lowercased() == "http",
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            return components.url
        }
        return nil
    }

    func adjustScrollViewInsets(safeAreaInsets: UIEdgeInsets) {
        scrollView.scrollIndicatorInsets = safeAreaInsets
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: safeAreaInsets.bottom, right: 0)
    }

    private func setupView() {
        backgroundColor = AppColors.black
        setupScrollView()
        setupHero()
        setupContent()
    }

    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupHero() {
        scrollView.addSubview(heroContainer)
        heroContainer.addSubview(heroImageView)

        heroContainer.backgroundColor = AppColors.darkGray
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true

        heroContainer.snp.makeConstraints { make in
            make.top.equalTo(scrollView)
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(heroContainer.snp.width).multipliedBy(Constants.imageHeightRatio)
        }

        heroImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupContent() {
        scrollView.addSubview(contentBackgroundView)
        scrollView.addSubview(contentView)

        contentBackgroundView.backgroundColor = AppColors.black
        contentBackgroundView.layer.cornerRadius = 32
        contentBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        contentBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(-40)
            make.leading.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(-30)
            make.leading.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }

        let stack = UIStackView(arrangedSubviews: [
            headerView,
            metricsView,
            overviewView,
            firstStageView,
            secondStageView,
            footerView
        ])
        stack.axis = .vertical
        stack.spacing = 40

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(48)
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview().inset(40)
        }

        headerView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
        }

        metricsView.snp.makeConstraints { make in
            make.height.equalTo(96)
        }
    }
}

extension RocketView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY < 0 {
            heroImageView.transform = CGAffineTransform(translationX: 0, y: offsetY).scaledBy(x: 1.0 - (offsetY / 700), y: 1.0 - (offsetY / 700))
        } else {
            heroImageView.transform = .identity
        }
    }
}

private extension RocketView {
    enum Constants {
        static let imageHeightRatio: CGFloat = 0.8
        static let imageFadeDuration: TimeInterval = 0.3
    }
}

#Preview {
    let rocketView = RocketView()
    let viewController = UIViewController()
    viewController.view = rocketView
    return viewController
}
