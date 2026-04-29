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

    func testLoadNextPageIfNeededCanSucceedAfterTransientFailureOnRetry() {
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
        service.setSequentialResponses(
            for: 2,
            responses: [
                .failure(TestError.transient),
                .success(
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
        let firstAttemptExpectation = expectation(description: "First next-page attempt fails")
        let retryExpectation = expectation(description: "Retry next-page attempt succeeds")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            if case .failure(let error) = result {
                XCTFail("Expected success, got \(error)")
            }
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 1)

        viewModel.loadNextPageIfNeeded(rocketId: "rocket-1", currentIndex: 15) { result in
            switch result {
            case .success:
                XCTFail("Expected transient failure on first next-page attempt")
            case .failure:
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 20)
                XCTAssertTrue(viewModel.hasNextPage(for: "rocket-1"))
                XCTAssertFalse(viewModel.isLoadingPage(for: "rocket-1"))
            }
            firstAttemptExpectation.fulfill()
        }
        wait(for: [firstAttemptExpectation], timeout: 1)

        viewModel.loadNextPageIfNeeded(rocketId: "rocket-1", currentIndex: 15) { result in
            switch result {
            case .success(let launches):
                XCTAssertEqual(launches.count, 22)
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 22)
                XCTAssertFalse(viewModel.hasNextPage(for: "rocket-1"))
                XCTAssertFalse(viewModel.isLoadingPage(for: "rocket-1"))
            case .failure(let error):
                XCTFail("Expected success on retry, got \(error)")
            }
            retryExpectation.fulfill()
        }
        wait(for: [retryExpectation], timeout: 1)

        XCTAssertEqual(service.requestedPages, [1, 2, 2])
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
    private var sequentialResponsesByPage: [Int: [Result<LaunchPage, Error>]] = [:]
    private(set) var requestedPages: [Int] = []

    init(responsesByPage: [Int: Result<LaunchPage, Error>]) {
        self.responsesByPage = responsesByPage
    }

    func setSequentialResponses(
        for page: Int,
        responses: [Result<LaunchPage, Error>]
    ) {
        sequentialResponsesByPage[page] = responses
    }

    func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        completion: @escaping (Result<LaunchPage, Error>) -> Void
    ) {
        requestedPages.append(page)
        if var sequential = sequentialResponsesByPage[page], !sequential.isEmpty {
            let nextResult = sequential.removeFirst()
            sequentialResponsesByPage[page] = sequential
            completion(nextResult)
            return
        }

        completion(responsesByPage[page] ?? .failure(TestError.missingResponse))
    }
}

private enum TestError: Error {
    case missingResponse
    case transient
}
