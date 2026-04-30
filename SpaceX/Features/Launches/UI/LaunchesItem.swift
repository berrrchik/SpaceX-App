import UIKit

enum LaunchesItem: Hashable {
    case filter(LaunchFilterItem)
    case launch(LaunchCellViewModel)
    case message(String)
}

typealias LaunchesSnapshot = NSDiffableDataSourceSnapshot<LaunchesSection, LaunchesItem>

enum LaunchesSnapshotBuilder {
    static func make(
        state: LoadableState<[LaunchCellViewModel]>,
        filters: [LaunchFilterItem]
    ) -> LaunchesSnapshot {
        var snapshot = LaunchesSnapshot()

        if !filters.isEmpty {
            snapshot.appendSections([.filters])
            snapshot.appendItems(filters.map { .filter($0) }, toSection: .filters)
        }

        switch state {
        case .loaded(let items, _):
            snapshot.appendSections([.launches])
            snapshot.appendItems(items.map { .launch($0) }, toSection: .launches)
        case .failed(_, let cachedValue):
            if let cachedValue, !cachedValue.isEmpty {
                snapshot.appendSections([.launches])
                snapshot.appendItems(cachedValue.map { .launch($0) }, toSection: .launches)
            } else {
                snapshot.appendSections([.message])
                snapshot.appendItems([.message(L10n.launchesNetworkError)], toSection: .message)
            }
        case .empty(let message):
            snapshot.appendSections([.message])
            snapshot.appendItems([.message(message)], toSection: .message)
        case .idle, .loading:
            break
        }

        return snapshot
    }
}
