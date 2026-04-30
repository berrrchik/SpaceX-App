import UIKit
import SnapKit

final class LaunchView: UIView {
    let collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout { _, _ in nil })
    }()
    private let loadingOverlayView = LoadingView()
    var onBackButtonTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(collectionView)
        setupCollectionView()
        setupLoadingOverlay()
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = AppColors.clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(LaunchCell.self, forCellWithReuseIdentifier: LaunchCell.reuseId)
        collectionView.register(LaunchErrorCell.self, forCellWithReuseIdentifier: LaunchErrorCell.reuseId)
        collectionView.register(LaunchFilterCell.self, forCellWithReuseIdentifier: LaunchFilterCell.reuseId)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(Constants.tableTopOffset)
            make.leading.equalToSuperview().offset(Constants.horizontalMargin)
            make.trailing.equalToSuperview().inset(Constants.horizontalMargin)
            make.bottom.equalToSuperview()
        }
    }

    private func setupLoadingOverlay() {
        addSubview(loadingOverlayView)
        loadingOverlayView.isHidden = true
        loadingOverlayView.isUserInteractionEnabled = false

        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }

    func showLoadingOverlay() {
        loadingOverlayView.isHidden = false
        loadingOverlayView.startRotationAnimation()
    }

    func hideLoadingOverlay() {
        loadingOverlayView.isHidden = true
        loadingOverlayView.stopRotationAnimation()
    }
    
    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }

    static func makeLayout(sectionProvider: @escaping (Int) -> LaunchesSection?) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionProvider(sectionIndex) {
            case .filters:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .estimated(80),
                        heightDimension: .absolute(36)
                    )
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .estimated(80),
                        heightDimension: .absolute(36)
                    ),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 8
                return section

            case .launches:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(120)
                    )
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(120)
                    ),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(56)
                    ),
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom
                )
                section.boundarySupplementaryItems = [footer]
                return section

            case .message:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(100)
                    )
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(100)
                    ),
                    subitems: [item]
                )
                return NSCollectionLayoutSection(group: group)

            case .none:
                return nil
            }
        }
    }
}

private extension LaunchView {
    enum Constants {
        static let tableTopOffset: CGFloat = 0
        static let horizontalMargin: CGFloat = 16
        static let estimatedRowHeight: CGFloat = 120
    }
}
