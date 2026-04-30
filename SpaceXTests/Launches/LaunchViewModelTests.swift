import XCTest
@testable import SpaceX

final class LaunchViewModelTests: XCTestCase {
    func testFetchInitialLaunchesLoadsFirstPageAndCachesIt() {
        let repository = MockLaunchRepository(
            responsesByPage: [
                1: .success(
                    LaunchPageResult(
                        launches: [
                            Launch(id: "second", name: "Second", dateUtc: "2023-05-01T00:00:00.000Z", formattedDate: "01.05.2023", success: true, rocketId: "rocket-1"),
                            Launch(id: "first", name: "First", dateUtc: "2024-01-01T00:00:00.000Z", formattedDate: "01.01.2024", success: false, rocketId: "rocket-1"),
                        ],
                        hasNextPage: true,
                        nextPage: 2
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchRepository: repository)
        let expectation = expectation(description: "Initial launches loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            switch result {
            case .success(let launches):
                XCTAssertEqual(launches.map(\.name), ["First", "Second"])
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 2)
                XCTAssertEqual(repository.requestedPages, [1])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testLoadNextPageIfNeededMergesNextPageWhenThresholdIsReached() {
        let repository = MockLaunchRepository(
            responsesByPage: [
                1: .success(
                    LaunchPageResult(
                        launches: Self.makeLaunches(prefix: "Page1", count: 20, rocketId: "rocket-1", dayOffset: 0),
                        hasNextPage: true,
                        nextPage: 2
                    )
                ),
                2: .success(
                    LaunchPageResult(
                        launches: Self.makeLaunches(prefix: "Page2", count: 2, rocketId: "rocket-1", dayOffset: 20),
                        hasNextPage: false,
                        nextPage: nil
                    )
                ),
            ]
        )
        let viewModel = LaunchViewModel(launchRepository: repository)
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
                XCTAssertEqual(repository.requestedPages, [1, 2])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            nextPageExpectation.fulfill()
        }

        wait(for: [nextPageExpectation], timeout: 1)
    }

    func testLoadNextPageIfNeededDoesNothingBeforeThreshold() {
        let repository = MockLaunchRepository(
            responsesByPage: [
                1: .success(
                    LaunchPageResult(
                        launches: Self.makeLaunches(prefix: "Page1", count: 20, rocketId: "rocket-1", dayOffset: 0),
                        hasNextPage: true,
                        nextPage: 2
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchRepository: repository)
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

        XCTAssertEqual(repository.requestedPages, [1])
        XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 20)
    }

    func testFetchInitialLaunchesSupportsEmptyLaunchState() {
        let repository = MockLaunchRepository(
            responsesByPage: [
                1: .success(
                    LaunchPageResult(
                        launches: [],
                        hasNextPage: false,
                        nextPage: nil
                    )
                )
            ]
        )
        let viewModel = LaunchViewModel(launchRepository: repository)
        let expectation = expectation(description: "Empty initial page loaded")

        viewModel.fetchInitialLaunches(rocketId: "rocket-1") { result in
            switch result {
            case .success(let launches):
                XCTAssertTrue(launches.isEmpty)
                XCTAssertEqual(viewModel.numberOfLaunches(for: "rocket-1"), 0)
                XCTAssertFalse(viewModel.hasNextPage(for: "rocket-1"))
                XCTAssertEqual(repository.requestedPages, [1])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testLoadNextPageIfNeededCanSucceedAfterTransientFailureOnRetry() {
        let repository = MockLaunchRepository(
            responsesByPage: [
                1: .success(
                    LaunchPageResult(
                        launches: Self.makeLaunches(prefix: "Page1", count: 20, rocketId: "rocket-1", dayOffset: 0),
                        hasNextPage: true,
                        nextPage: 2
                    )
                )
            ]
        )
        repository.setSequentialResponses(
            for: 2,
            responses: [
                .failure(TestError.transient),
                .success(
                    LaunchPageResult(
                        launches: Self.makeLaunches(prefix: "Page2", count: 2, rocketId: "rocket-1", dayOffset: 20),
                        hasNextPage: false,
                        nextPage: nil
                    )
                ),
            ]
        )

        let viewModel = LaunchViewModel(launchRepository: repository)
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

        XCTAssertEqual(repository.requestedPages, [1, 2, 2])
    }

    private static func makeLaunches(prefix: String, count: Int, rocketId: String, dayOffset: Int) -> [Launch] {
        (0..<count).map { index in
            let day = String(format: "%02d", index + 1 + dayOffset)
            return Launch(
                id: "\(prefix.lowercased())-\(index)",
                name: "\(prefix)-\(index)",
                dateUtc: "2024-01-\(day)T00:00:00.000Z",
                formattedDate: "\(day).01.2024",
                success: true,
                rocketId: rocketId
            )
        }
    }
}

private final class MockLaunchRepository: LaunchRepositoryProtocol {
    let responsesByPage: [Int: Result<LaunchPageResult, Error>]
    private var sequentialResponsesByPage: [Int: [Result<LaunchPageResult, Error>]] = [:]
    private(set) var requestedPages: [Int] = []

    init(responsesByPage: [Int: Result<LaunchPageResult, Error>]) {
        self.responsesByPage = responsesByPage
    }

    func setSequentialResponses(
        for page: Int,
        responses: [Result<LaunchPageResult, Error>]
    ) {
        sequentialResponsesByPage[page] = responses
    }

    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        requestedPages.append(1)
        if var sequential = sequentialResponsesByPage[1], !sequential.isEmpty {
            let nextResult = sequential.removeFirst()
            sequentialResponsesByPage[1] = sequential
            return try nextResult.get()
        }
        return try (responsesByPage[1] ?? .failure(TestError.missingResponse)).get()
    }

    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        requestedPages.append(page)
        if var sequential = sequentialResponsesByPage[page], !sequential.isEmpty {
            let nextResult = sequential.removeFirst()
            sequentialResponsesByPage[page] = sequential
            return try nextResult.get()
        }
        return try (responsesByPage[page] ?? .failure(TestError.missingResponse)).get()
    }
}

private enum TestError: Error {
    case missingResponse
    case transient
}
