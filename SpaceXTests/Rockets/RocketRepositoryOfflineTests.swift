import XCTest
import Combine
@testable import SpaceX

final class RocketRepositoryOfflineTests: XCTestCase {
    private static let suiteName = "com.test.rocketRepositoryOffline"

    private var testDefaults: UserDefaults!
    private var cacheStore: UserDefaultsRocketCacheStore!
    private var remoteDataSource: MockRocketRemoteDataSource!
    private var fallbackDataSource: MockRocketFallbackDataSource!
    private var networkMonitor: MockNetworkMonitor!
    private var sut: RocketRepository!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.suiteName)
        cacheStore = UserDefaultsRocketCacheStore(defaults: testDefaults)
        remoteDataSource = MockRocketRemoteDataSource()
        fallbackDataSource = MockRocketFallbackDataSource()
        networkMonitor = MockNetworkMonitor(isConnected: true)
        sut = RocketRepository(
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

    func test_fetchRockets_networkFailure_returnsCachedData() async throws {
        let cached = Self.makeRocket(id: "rocket-cached")
        cacheStore.save([cached])
        remoteDataSource.stubbedError = NetworkError.transport(URLError(.notConnectedToInternet))

        let result = try await sut.fetchRockets()

        XCTAssertEqual(result.map(\.id), ["rocket-cached"])
    }

    func test_fetchRockets_networkFailure_emptyCache_returnsBundledFallback() async throws {
        remoteDataSource.stubbedError = NetworkError.transport(URLError(.notConnectedToInternet))
        fallbackDataSource.stubbedRockets = [
            Self.makeRocketDTO(id: "rocket-fallback")
        ]

        let result = try await sut.fetchRockets()

        XCTAssertEqual(result.map(\.id), ["rocket-fallback"])
        XCTAssertEqual(fallbackDataSource.fetchRocketsCallCount, 1)
        XCTAssertEqual(cacheStore.load()?.map(\.id), ["rocket-fallback"])
    }

    func test_fetchRockets_offlineWithoutRequest_returnsCachedData() async throws {
        let cached = Self.makeRocket(id: "rocket-cached")
        cacheStore.save([cached])
        networkMonitor.isConnectedValue = false

        let result = try await sut.fetchRockets()

        XCTAssertEqual(result.map(\.id), ["rocket-cached"])
        XCTAssertEqual(remoteDataSource.fetchRocketsCallCount, 0)
    }

    func test_fetchRockets_offlineEmptyCache_returnsBundledFallbackWithoutRequest() async throws {
        networkMonitor.isConnectedValue = false
        fallbackDataSource.stubbedRockets = [
            Self.makeRocketDTO(id: "rocket-fallback")
        ]

        let result = try await sut.fetchRockets()

        XCTAssertEqual(result.map(\.id), ["rocket-fallback"])
        XCTAssertEqual(remoteDataSource.fetchRocketsCallCount, 0)
        XCTAssertEqual(fallbackDataSource.fetchRocketsCallCount, 1)
    }

    func test_fetchRockets_networkFailure_emptyCache_fallbackFailure_throwsOriginalError() async {
        remoteDataSource.stubbedError = NetworkError.server(statusCode: 525, data: nil)
        fallbackDataSource.stubbedError = NetworkError.emptyResponse

        do {
            _ = try await sut.fetchRockets()
            XCTFail("Expected error")
        } catch let error as NetworkError {
            guard case .server(let statusCode, _) = error else {
                return XCTFail("Expected server error")
            }
            XCTAssertEqual(statusCode, 525)
        } catch {
            XCTFail("Expected NetworkError")
        }
    }
}

private final class MockRocketRemoteDataSource: RocketRemoteDataSourceProtocol {
    var stubbedError: Error?
    var stubbedRockets: [RocketDTO] = []
    private(set) var fetchRocketsCallCount = 0

    func fetchRockets() async throws -> [RocketDTO] {
        fetchRocketsCallCount += 1
        if let stubbedError {
            throw stubbedError
        }
        return stubbedRockets
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

private final class MockRocketFallbackDataSource: RocketFallbackDataSourceProtocol {
    var stubbedError: Error?
    var stubbedRockets: [RocketDTO] = []
    private(set) var fetchRocketsCallCount = 0

    func fetchRockets() throws -> [RocketDTO] {
        fetchRocketsCallCount += 1
        if let stubbedError {
            throw stubbedError
        }
        return stubbedRockets
    }
}

private extension RocketRepositoryOfflineTests {
    static func makeRocket(id: String) -> Rocket {
        Rocket(
            id: id,
            name: "Rocket \(id)",
            country: "US",
            costPerLaunch: 100,
            firstFlightDate: "01.01.2020",
            height: MeasureSize(meters: 1, feet: 3),
            diameter: MeasureSize(meters: 1, feet: 3),
            mass: MeasureWeight(kg: 100, lb: 220),
            firstStage: FirstStage(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            secondStage: SecondStage(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            payloadWeights: [MeasureWeight(kg: 10, lb: 22)],
            flickrImages: []
        )
    }

    static func makeRocketDTO(id: String) -> RocketDTO {
        RocketDTO(
            height: MeasureSizeDTO(meters: 1, feet: 3),
            diameter: MeasureSizeDTO(meters: 1, feet: 3),
            mass: MeasureWeightDTO(kg: 100, lb: 220),
            firstStage: FirstStageDTO(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            secondStage: SecondStageDTO(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            payloadWeights: [MeasureWeightDTO(kg: 10, lb: 22)],
            flickrImages: [],
            name: "Rocket \(id)",
            costPerLaunch: 100,
            firstFlight: "2020-01-01",
            country: "US",
            id: id
        )
    }
}
