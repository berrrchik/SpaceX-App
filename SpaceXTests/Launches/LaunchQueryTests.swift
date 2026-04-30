import XCTest
@testable import SpaceX

final class LaunchQueryTests: XCTestCase {
    func test_searchText_caseInsensitive_matchesSubstring() {
        let sut = makeSUT(with: [
            Launch(id: "1", name: "FalconSat", dateUtc: "2006-03-24T00:00:00.000Z", formattedDate: "", success: false, rocketId: "r"),
            Launch(id: "2", name: "Starlink", dateUtc: "2020-01-01T00:00:00.000Z", formattedDate: "", success: true, rocketId: "r")
        ])

        let exp = expectation(description: "query applied")
        sut.applyQuery(LaunchQuery(searchText: "falcon")) { state in
            if case .loaded(let items, _) = state {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.name, "FalconSat")
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_sortOrder_oldestFirst_ascendingDate() {
        let sut = makeSUT(with: [
            Launch(id: "1", name: "B", dateUtc: "2020-01-01T00:00:00.000Z", formattedDate: "", success: true, rocketId: "r"),
            Launch(id: "2", name: "A", dateUtc: "2006-03-24T00:00:00.000Z", formattedDate: "", success: false, rocketId: "r")
        ])

        let exp = expectation(description: "sorted")
        sut.applyQuery(LaunchQuery(searchText: "", statusFilter: .all, year: nil, sortOrder: .oldestFirst)) { state in
            if case .loaded(let items, _) = state {
                XCTAssertEqual(items.first?.name, "A")
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_applyQuery_doesNotTriggerAdditionalNetworkRequests() {
        let repository = QueryMockLaunchRepository(launches: [
            Launch(id: "1", name: "FalconSat", dateUtc: "2006-03-24T00:00:00.000Z", formattedDate: "", success: false, rocketId: "r")
        ])
        let sut = LaunchListViewModel(launchRepository: repository)

        let initial = expectation(description: "initial")
        sut.loadInitialLaunches(for: "r") { state in
            if case .loaded = state {
                initial.fulfill()
            }
        }
        wait(for: [initial], timeout: 1.0)

        let callsBefore = repository.fetchInitialCallCount + repository.fetchNextCallCount
        let apply = expectation(description: "apply")
        sut.applyQuery(LaunchQuery(searchText: "falcon")) { _ in apply.fulfill() }
        wait(for: [apply], timeout: 1.0)

        let callsAfter = repository.fetchInitialCallCount + repository.fetchNextCallCount
        XCTAssertEqual(callsBefore, callsAfter)
    }

    private func makeSUT(with launches: [Launch]) -> LaunchListViewModel {
        let repository = QueryMockLaunchRepository(launches: launches)
        let sut = LaunchListViewModel(launchRepository: repository)
        let initial = expectation(description: "initial loaded")
        sut.loadInitialLaunches(for: "r") { state in
            if case .loaded = state {
                initial.fulfill()
            }
        }
        wait(for: [initial], timeout: 1.0)
        return sut
    }
}

private final class QueryMockLaunchRepository: LaunchRepositoryProtocol {
    let launches: [Launch]
    private(set) var fetchInitialCallCount = 0
    private(set) var fetchNextCallCount = 0

    init(launches: [Launch]) {
        self.launches = launches
    }

    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        fetchInitialCallCount += 1
        return LaunchPageResult(launches: launches, hasNextPage: false, nextPage: nil)
    }

    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        fetchNextCallCount += 1
        return LaunchPageResult(launches: [], hasNextPage: false, nextPage: nil)
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        launches
    }
}
