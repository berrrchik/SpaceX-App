import XCTest
@testable import SpaceX

final class LaunchListViewModelTests: XCTestCase {
    func testLoadInitialLaunchesReturnsContentState() {
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
        let expectation = expectation(description: "content state returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            switch state {
            case .content(let items):
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.name, "L1")
            default:
                XCTFail("Expected content state")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoadInitialLaunchesReturnsEmptyState() {
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
            if case .empty = state {
                expectation.fulfill()
            } else {
                XCTFail("Expected empty state")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoadInitialLaunchesReturnsErrorState() {
        let repository = MockLaunchListRepository(
            initialResult: .failure(MockError.failed),
            nextPageResults: [:]
        )
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let expectation = expectation(description: "error state returned")

        viewModel.loadInitialLaunches(for: "r1") { state in
            switch state {
            case .error(let message):
                XCTAssertFalse(message.isEmpty)
            default:
                XCTFail("Expected error state")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoadNextPageIfNeededAppendsItemsWhenThresholdReached() {
        let repository = MockLaunchListRepository(
            initialResult: .success(
                LaunchPageResult(
                    launches: (0..<10).map {
                        Launch(id: "p1-\($0)", name: "P1-\($0)", dateUtc: "2024-01-01T00:00:00.000Z", formattedDate: "01.01.2024", success: true, rocketId: "r1")
                    },
                    hasNextPage: true,
                    nextPage: 2
                )
            ),
            nextPageResults: [
                2: .success(
                    LaunchPageResult(
                        launches: [
                            Launch(id: "p2-0", name: "P2-0", dateUtc: "2024-01-02T00:00:00.000Z", formattedDate: "02.01.2024", success: true, rocketId: "r1")
                        ],
                        hasNextPage: false,
                        nextPage: nil
                    )
                )
            ]
        )
        let viewModel = LaunchListViewModel(launchRepository: repository)
        let initial = expectation(description: "initial loaded")
        let next = expectation(description: "next page loaded")

        viewModel.loadInitialLaunches(for: "r1") { _ in
            initial.fulfill()
        }
        wait(for: [initial], timeout: 1.0)

        viewModel.loadNextPageIfNeeded(for: "r1", currentIndex: 9, totalItems: 10) { state in
            switch state {
            case .content(let items):
                XCTAssertEqual(items.count, 11)
                XCTAssertEqual(items.last?.name, "P2-0")
            default:
                XCTFail("Expected content state after next page")
            }
            next.fulfill()
        }

        wait(for: [next], timeout: 1.0)
    }
}

private final class MockLaunchListRepository: LaunchRepositoryProtocol {
    private let initialResult: Result<LaunchPageResult, Error>
    private let nextPageResults: [Int: Result<LaunchPageResult, Error>]

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
        try (nextPageResults[page] ?? .failure(MockError.failed)).get()
    }
}

private enum MockError: Error {
    case failed
}
