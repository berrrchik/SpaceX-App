import XCTest
@testable import SpaceX

final class LaunchDetailViewModelTests: XCTestCase {
    func test_load_success_transitionsToLoaded() {
        let repo = MockLaunchDetailRepository(result: .success(Self.makeDetail()))
        let sut = LaunchDetailViewModel(launchId: "l1", repository: repo)
        let exp = expectation(description: "loaded")

        sut.onStateChange = { state in
            if case .loaded(let detail, let isStale) = state {
                XCTAssertEqual(detail.launch.id, "l1")
                XCTAssertFalse(isStale)
                exp.fulfill()
            }
        }

        sut.load()
        wait(for: [exp], timeout: 1)
    }

    func test_load_repositoryFailure_transitionsToFailed() {
        let repo = MockLaunchDetailRepository(result: .failure(MockError.failed))
        let sut = LaunchDetailViewModel(launchId: "l1", repository: repo)
        let exp = expectation(description: "failed")

        sut.onStateChange = { state in
            if case .failed(let message, let cached) = state {
                XCTAssertFalse(message.isEmpty)
                XCTAssertNil(cached)
                exp.fulfill()
            }
        }

        sut.load()
        wait(for: [exp], timeout: 1)
    }

    private static func makeDetail() -> LaunchDetail {
        LaunchDetail(
            launch: Launch(
                id: "l1",
                name: "Launch 1",
                dateUtc: "2024-01-01T00:00:00.000Z",
                formattedDate: "01.01.2024",
                success: true,
                rocketId: "r1"
            ),
            launchpad: nil,
            isStale: false
        )
    }
}

private final class MockLaunchDetailRepository: LaunchDetailRepositoryProtocol {
    let result: Result<LaunchDetail, Error>

    init(result: Result<LaunchDetail, Error>) {
        self.result = result
    }

    func fetchDetail(for launchId: String) async throws -> LaunchDetail {
        try result.get()
    }
}

private enum MockError: Error {
    case failed
}
