import XCTest
@testable import SpaceX

final class LaunchListViewModelTests: XCTestCase {
    func test_loadInitialLaunches_success_transitionsToLoaded() {
        let repository = MockLaunchListRepository(
            initialResult: .success(
                LaunchPageResult(
                    launches: [
                        Launch(id: "l1", name: "L1", dateUtc: "2024-01-01T00:00:00.000Z", formattedDate: "01.01.2024", success: true, rocketId: "r1")
                    ],
                    hasNextPage: true,
                    nextPage: 2
                )
            ),
            nextPageResults: [:]
        )
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let expectation = expectation(description: "loaded state returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            switch state {
            case .loaded(let items, let isStale):
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.name, "L1")
                XCTAssertFalse(isStale)
            default:
                break
            }
            if case .loaded = state { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadInitialLaunches_emptyResult_transitionsToEmpty() {
        let repository = MockLaunchListRepository(
            initialResult: .success(
                LaunchPageResult(
                    launches: [],
                    hasNextPage: false,
                    nextPage: nil
                )
            ),
            nextPageResults: [:]
        )
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let expectation = expectation(description: "empty state returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            if case .empty(let message) = state {
                XCTAssertFalse(message.isEmpty)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadInitialLaunches_networkFailure_withCache_transitionsToFailed_withCachedValue() {
        let repository = MockLaunchListRepository(
            initialResult: .failure(MockError.failed),
            nextPageResults: [:]
        )
        repository.cachedLaunches = [
            Launch(id: "cached", name: "Cached", dateUtc: "2024-01-01T00:00:00.000Z", formattedDate: "01.01.2024", success: true, rocketId: "r1")
        ]
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let expectation = expectation(description: "failed with cache returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            switch state {
            case .failed(let message, let cached):
                XCTAssertFalse(message.isEmpty)
                XCTAssertEqual(cached?.count, 1)
                expectation.fulfill()
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadInitialLaunches_networkFailure_noCache_transitionsToFailed_nilCachedValue() {
        let repository = MockLaunchListRepository(
            initialResult: .failure(MockError.failed),
            nextPageResults: [:]
        )
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let expectation = expectation(description: "failed no cache returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            if case .failed(_, let cached) = state {
                XCTAssertNil(cached)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

private final class MockLaunchListRepository: LaunchRepositoryProtocol {
    private let initialResult: Result<LaunchPageResult, Error>
    private let nextPageResults: [Int: Result<LaunchPageResult, Error>]
    private(set) var fetchNextPageCallCount = 0
    var cachedLaunches: [Launch] = []

    init(
        initialResult: Result<LaunchPageResult, Error>,
        nextPageResults: [Int: Result<LaunchPageResult, Error>]
    ) {
        self.initialResult = initialResult
        self.nextPageResults = nextPageResults
    }

    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        try initialResult.get()
    }

    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        fetchNextPageCallCount += 1
        return try (nextPageResults[page] ?? .failure(MockError.failed)).get()
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        cachedLaunches
    }
}

private enum MockError: Error {
    case failed
}
