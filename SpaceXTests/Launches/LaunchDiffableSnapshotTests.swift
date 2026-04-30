import XCTest
@testable import SpaceX

final class LaunchDiffableSnapshotTests: XCTestCase {
    func test_snapshot_initialLoadingState_hasNoSections() {
        let snapshot = LaunchesSnapshotBuilder.make(state: .loading, filters: [])
        XCTAssertTrue(snapshot.sectionIdentifiers.isEmpty)
    }

    func test_snapshot_contentState_hasLaunchesSection() {
        let launch = LaunchCellViewModel(
            id: "l1",
            name: "FalconSat",
            date: "01.01.2024",
            statusImageName: "LaunchSuccess"
        )
        let snapshot = LaunchesSnapshotBuilder.make(state: .loaded([launch], isStale: false), filters: [])

        XCTAssertEqual(snapshot.sectionIdentifiers, [.launches])
        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    func test_snapshot_emptyState_hasMessageSection() {
        let snapshot = LaunchesSnapshotBuilder.make(state: .empty(message: "No data"), filters: [])
        XCTAssertEqual(snapshot.sectionIdentifiers, [.message])
        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    func test_snapshot_errorState_hasMessageSection_whenNoCache() {
        let snapshot = LaunchesSnapshotBuilder.make(
            state: .failed(message: "Error", cachedValue: nil),
            filters: []
        )
        XCTAssertEqual(snapshot.sectionIdentifiers, [.message])
        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    func test_snapshot_filterSectionPresent_whenFiltersAvailable() {
        let filters = [
            LaunchFilterItem(id: "all", title: "All", isSelected: true),
            LaunchFilterItem(id: "success", title: "Success", isSelected: false)
        ]
        let snapshot = LaunchesSnapshotBuilder.make(state: .loading, filters: filters)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.filters])
        XCTAssertEqual(snapshot.numberOfItems, 2)
    }
}
