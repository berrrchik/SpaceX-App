import XCTest
import Combine
@testable import SpaceX

final class LaunchRepositoryOfflineTests: XCTestCase {
    private static let suiteName = "com.test.launchRepositoryOffline"

    private var testDefaults: UserDefaults!
    private var cacheStore: UserDefaultsLaunchCacheStore!
    private var remoteDataSource: MockLaunchRemoteDataSource!
    private var networkMonitor: MockNetworkMonitor!
    private var sut: LaunchRepository!

    override func setUp() {
        super.setUp()
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            XCTFail("Failed to create test defaults suite")
            return
        }
        testDefaults = defaults
        cacheStore = UserDefaultsLaunchCacheStore(defaults: defaults)
        remoteDataSource = MockLaunchRemoteDataSource()
        networkMonitor = MockNetworkMonitor(isConnected: true)
        sut = LaunchRepository(
            remoteDataSource: remoteDataSource,
            cacheStore: cacheStore,
            networkMonitor: networkMonitor
        )
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        sut = nil
        remoteDataSource = nil
        networkMonitor = nil
        cacheStore = nil
        testDefaults = nil
        super.tearDown()
    }

    func test_fetchInitialLaunches_networkFailure_returnsCachedData() async throws {
        let cached = Launch(
            id: "cached-1",
            name: "Cached launch",
            dateUtc: "2024-01-01T00:00:00.000Z",
            formattedDate: "01.01.2024",
            success: true,
            rocketId: "rocket-x"
        )
        cacheStore.save([cached], for: "rocket-x")
        remoteDataSource.stubbedError = NetworkError.transport(URLError(.notConnectedToInternet))

        let result = try await sut.fetchInitialLaunches(for: "rocket-x")

        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.map(\.id), ["cached-1"])
        XCTAssertFalse(result.hasNextPage)
    }

    func test_fetchInitialLaunches_networkFailure_emptyCache_throws() async {
        remoteDataSource.stubbedError = NetworkError.transport(URLError(.notConnectedToInternet))

        do {
            _ = try await sut.fetchInitialLaunches(for: "rocket-x")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_fetchInitialLaunches_offlineWithoutRequest_returnsCachedData() async throws {
        let cached = Launch(
            id: "cached-1",
            name: "Cached launch",
            dateUtc: "2024-01-01T00:00:00.000Z",
            formattedDate: "01.01.2024",
            success: true,
            rocketId: "rocket-x"
        )
        cacheStore.save([cached], for: "rocket-x")
        networkMonitor.isConnectedValue = false

        let result = try await sut.fetchInitialLaunches(for: "rocket-x")

        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.map(\.id), ["cached-1"])
        XCTAssertEqual(remoteDataSource.fetchLaunchPageCallCount, 0)
    }

    func test_fetchInitialLaunches_offlineWithCachedEmptyState_returnsEmptyStaleResult() async throws {
        cacheStore.save([], for: "rocket-empty")
        networkMonitor.isConnectedValue = false

        let result = try await sut.fetchInitialLaunches(for: "rocket-empty")

        XCTAssertTrue(result.isStale)
        XCTAssertTrue(result.launches.isEmpty)
        XCTAssertFalse(result.hasNextPage)
        XCTAssertEqual(remoteDataSource.fetchLaunchPageCallCount, 0)
    }
}

private final class MockLaunchRemoteDataSource: LaunchRemoteDataSourceProtocol {
    var stubbedError: Error?
    var stubbedPage = LaunchPageDTO(docs: [], hasNextPage: false, nextPage: nil)
    private(set) var fetchLaunchPageCallCount = 0

    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) async throws -> LaunchPageDTO {
        fetchLaunchPageCallCount += 1
        if let stubbedError {
            throw stubbedError
        }
        return stubbedPage
    }
}

private final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnectedValue: Bool

    var connectivityPublisher: AnyPublisher<ConnectivityStatus, Never> {
        Just(connectivityStatus).eraseToAnyPublisher()
    }

    var connectionRestoredPublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var connectivityStatus: ConnectivityStatus {
        isConnectedValue ? .connected : .disconnected
    }

    init(isConnected: Bool) {
        self.isConnectedValue = isConnected
    }

    func isConnected() -> Bool {
        isConnectedValue
    }
}
