import XCTest
@testable import SpaceX

final class LaunchViewModelTests: XCTestCase {
    func testFetchInitialLaunchesLoadsFirstPageAndCachesIt() {
        let service = StubLaunchService(
            responsesByPage: [
                1: .success(
                    LaunchPage(
                        launches: [
                            LaunchElement(name: "Second", dateUtc: "2023-05-01T00:00:00.000Z", success: true, rocket: "rocket-1"),
                            LaunchElement(name: "First", dateUtc: "2024-01-01T00:00:00.000Z", success: false, rocket: "rocket-1"),
                        ],
                        hasNextPage: true,
                        nextPage: 2
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchApiService: service)
        let expectation = expectation(description: "Initial launches loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            switch result {
            case .success(let launches):
                XCTAssertEqual(launches.map(\.name), ["First", "Second"])
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 2)
                XCTAssertEqual(service.requestedPages, [1])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testLoadNextPageIfNeededMergesNextPageWhenThresholdIsReached() {
        let service = StubLaunchService(
            responsesByPage: [
                1: .success(
                    LaunchPage(
                        launches: Self.makeLaunches(prefix: "Page1", count: 20, rocketId: "rocket-1", dayOffset: 0),
                        hasNextPage: true,
                        nextPage: 2
                    )
                ),
                2: .success(
                    LaunchPage(
                        launches: Self.makeLaunches(prefix: "Page2", count: 2, rocketId: "rocket-1", dayOffset: 20),
                        hasNextPage: false,
                        nextPage: nil
                    )
                ),
            ]
        )
        let viewModel = LaunchViewModel(launchApiService: service)
        let initialExpectation = expectation(description: "Initial page loaded")
        let nextPageExpectation = expectation(description: "Next page loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            if case .failure(let error) = result {
                XCTFail("Expected success, got \(error)")
            }
            initialExpectation.fulfill()
        }

        wait(for: [initialExpectation], timeout: 1)

        viewModel.loadNextPageIfNeeded(rocketId: "rocket-1", currentIndex: 15) { result in
            switch result {
            case .success(let launches):
                XCTAssertEqual(launches.count, 22)
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 22)
                XCTAssertEqual(service.requestedPages, [1, 2])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            nextPageExpectation.fulfill()
        }

        wait(for: [nextPageExpectation], timeout: 1)
    }

    func testLoadNextPageIfNeededDoesNothingBeforeThreshold() {
        let service = StubLaunchService(
            responsesByPage: [
                1: .success(
                    LaunchPage(
                        launches: Self.makeLaunches(prefix: "Page1", count: 20, rocketId: "rocket-1", dayOffset: 0),
                        hasNextPage: true,
                        nextPage: 2
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchApiService: service)
        let expectation = expectation(description: "Initial page loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            if case .failure(let error) = result {
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        viewModel.loadNextPageIfNeeded(rocketId: "rocket-1", currentIndex: 5) { _ in
            XCTFail("Next page should not be requested before threshold")
        }

        XCTAssertEqual(service.requestedPages, [1])
        XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 20)
    }

    func testFetchInitialLaunchesSupportsEmptyLaunchState() {
        let service = StubLaunchService(
            responsesByPage: [
                1: .success(
                    LaunchPage(
                        launches: [],
                        hasNextPage: false,
                        nextPage: nil
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchApiService: service)
        let expectation = expectation(description: "Empty initial page loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            switch result {
            case .success(let launches):
                XCTAssertTrue(launches.isEmpty)
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 0)
                XCTAssertFalse(viewModel.hasNextPage(for: "rocket-1"))
                XCTAssertEqual(service.requestedPages, [1])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    private static func makeLaunches(prefix: String, count: Int, rocketId: String, dayOffset: Int) -> [LaunchElement] {
        (0..<count).map { index in
            let day = String(format: "%02d", index + 1 + dayOffset)
            return LaunchElement(
                name: "\(prefix)-\(index)",
                dateUtc: "2024-01-\(day)T00:00:00.000Z",
                success: true,
                rocket: rocketId
            )
        }
    }
}

private final class StubLaunchService: LaunchServiceProtocol {
    let responsesByPage: [Int: Result<LaunchPage, Error>]
    private(set) var requestedPages: [Int] = []

    init(responsesByPage: [Int: Result<LaunchPage, Error>]) {
        self.responsesByPage = responsesByPage
    }

    func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        completion: @escaping (Result<LaunchPage, Error>) -> Void
    ) {
        requestedPages.append(page)
        completion(responsesByPage[page] ?? .failure(TestError.missingResponse))
    }
}

private enum TestError: Error {
    case missingResponse
}
