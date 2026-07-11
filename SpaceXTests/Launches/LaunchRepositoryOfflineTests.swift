import XCTest
import Combine
@testable import SpaceX

final class LaunchRepositoryOfflineTests: XCTestCase {
    private static let suiteName = "com.test.launchRepositoryOffline"

    private var testDefaults: UserDefaults!
    private var cacheStore: UserDefaultsLaunchCacheStore!
    private var remoteDataSource: MockLaunchRemoteDataSource!
    private var fallbackDataSource: MockLaunchFallbackDataSource!
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
        fallbackDataSource = MockLaunchFallbackDataSource()
        networkMonitor = MockNetworkMonitor(isConnected: true)
        sut = LaunchRepository(
            remoteDataSource: remoteDataSource,
            cacheStore: cacheStore,
            networkMonitor: networkMonitor,
            fallbackDataSource: fallbackDataSource
        )
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        sut = nil
        fallbackDataSource = nil
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

    func test_fetchInitialLaunches_networkFailure_emptyCache_returnsBundledFallback() async throws {
        remoteDataSource.stubbedError = NetworkError.transport(URLError(.notConnectedToInternet))
        fallbackDataSource.stubbedLaunches = [
            Self.makeLaunchDTO(id: "fallback-1", rocketId: "rocket-x")
        ]

        let result = try await sut.fetchInitialLaunches(for: "rocket-x")

        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.map(\.id), ["fallback-1"])
        XCTAssertEqual(cacheStore.load(for: "rocket-x")?.map(\.id), ["fallback-1"])
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

    func test_fetchInitialLaunches_offlineEmptyCache_returnsBundledFallbackWithoutRequest() async throws {
        networkMonitor.isConnectedValue = false
        fallbackDataSource.stubbedLaunches = [
            Self.makeLaunchDTO(id: "fallback-1", rocketId: "rocket-x")
        ]

        let result = try await sut.fetchInitialLaunches(for: "rocket-x")

        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.map(\.id), ["fallback-1"])
        XCTAssertEqual(remoteDataSource.fetchLaunchPageCallCount, 0)
    }

    func test_fetchNextLaunchPage_networkFailure_returnsBundledFallbackPage() async throws {
        remoteDataSource.stubbedError = NetworkError.server(statusCode: 525, data: nil)
        fallbackDataSource.stubbedLaunches = [
            Self.makeLaunchDTO(id: "fallback-1", rocketId: "rocket-x"),
            Self.makeLaunchDTO(id: "fallback-2", rocketId: "rocket-x")
        ]
        sut = LaunchRepository(
            remoteDataSource: remoteDataSource,
            cacheStore: cacheStore,
            networkMonitor: networkMonitor,
            fallbackDataSource: fallbackDataSource,
            pageSize: 1
        )

        let result = try await sut.fetchNextLaunchPage(for: "rocket-x", page: 2)

        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.map(\.id), ["fallback-2"])
        XCTAssertFalse(result.hasNextPage)
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

private final class MockLaunchFallbackDataSource: LaunchFallbackDataSourceProtocol {
    var stubbedLaunches: [LaunchDTO] = []

    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) throws -> LaunchPageDTO {
        let launches = stubbedLaunches.filter { $0.rocket == rocketId }
        let startIndex = max(page - 1, 0) * limit
        guard startIndex < launches.count else {
            return LaunchPageDTO(docs: [], hasNextPage: false, nextPage: nil)
        }
        let endIndex = min(startIndex + limit, launches.count)
        let docs = Array(launches[startIndex..<endIndex])
        return LaunchPageDTO(
            docs: docs,
            hasNextPage: endIndex < launches.count,
            nextPage: endIndex < launches.count ? page + 1 : nil
        )
    }

    func fetchLaunch(for launchId: String) throws -> LaunchDTO {
        guard let launch = stubbedLaunches.first(where: { $0.id == launchId }) else {
            throw LaunchDetailError.launchNotFound(id: launchId)
        }
        return launch
    }

    func fetchRocketSummary(for rocketId: String) -> RocketSummary? {
        RocketSummary(id: rocketId, name: "Fallback Rocket", type: "rocket")
    }

    func fetchLaunchpad(for launchpadId: String) -> Launchpad? {
        Launchpad(id: launchpadId, name: "Fallback Pad", fullName: nil, locality: nil, region: nil, latitude: nil, longitude: nil)
    }
}

private extension LaunchRepositoryOfflineTests {
    static func makeLaunchDTO(id: String, rocketId: String) -> LaunchDTO {
        LaunchDTO(
            id: id,
            name: "Fallback Launch",
            dateUtc: "2024-01-01T00:00:00.000Z",
            success: true,
            rocket: rocketId,
            upcoming: false,
            details: "Fallback details",
            launchpad: "pad-1",
            links: nil,
            cores: nil,
            payloads: ["payload-1"],
            crew: nil,
            ships: nil,
            capsules: nil
        )
    }
}
