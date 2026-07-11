import XCTest
import Combine
@testable import SpaceX

final class LaunchDetailRepositoryTests: XCTestCase {
    func test_fetch_returnsCombinedLaunchAndLaunchpad_fromNetwork() async throws {
        let launchDTO = LaunchDTO(
            id: "l1",
            name: "Launch",
            dateUtc: "2024-01-01T00:00:00.000Z",
            success: true,
            rocket: "r1",
            upcoming: false,
            details: nil,
            launchpad: "pad1",
            links: nil,
            cores: nil,
            payloads: ["p1"],
            crew: nil,
            ships: ["s1"],
            capsules: ["c1"]
        )
        let launchpad = Launchpad(id: "pad1", name: "Pad", fullName: nil, locality: "LC", region: "US", latitude: nil, longitude: nil)
        let sut = LaunchDetailRepository(
            launchDetailDataSource: MockDetailDS(dto: launchDTO),
            launchpadDataSource: MockLaunchpadDS(launchpad: launchpad),
            rocketDataSource: MockRocketDS(rocket: RocketSummary(id: "r1", name: "Falcon 1", type: "rocket")),
            payloadDataSource: MockPayloadDS(payload: Payload(id: "p1", name: "RazakSAT", type: "Satellite", massKg: nil, orbit: nil)),
            crewDataSource: MockCrewDS(crewMember: nil),
            capsuleDataSource: MockCapsuleDS(capsule: Capsule(id: "c1", serial: "C101", status: "active", type: "Dragon 2.0")),
            shipDataSource: MockShipDS(ship: Ship(id: "s1", name: "Elsbeth III", model: nil, type: "Tug", active: false, homePort: "Port Canaveral", imageURL: nil)),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fallbackDataSource: nil
        )

        let detail = try await sut.fetchDetail(for: "l1")

        XCTAssertEqual(detail.launch.id, "l1")
        XCTAssertEqual(detail.launchpad?.id, "pad1")
        XCTAssertFalse(detail.isStale)
    }

    func test_fetch_networkFailure_whenOnline_throws() async {
        let sut = LaunchDetailRepository(
            launchDetailDataSource: MockDetailDS(error: MockRepoError.failed),
            launchpadDataSource: MockLaunchpadDS(launchpad: nil),
            rocketDataSource: MockRocketDS(rocket: nil),
            payloadDataSource: MockPayloadDS(payload: nil),
            crewDataSource: MockCrewDS(crewMember: nil),
            capsuleDataSource: MockCapsuleDS(capsule: nil),
            shipDataSource: MockShipDS(ship: nil),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fallbackDataSource: nil
        )

        do {
            _ = try await sut.fetchDetail(for: "l1")
            XCTFail("Expected throw")
        } catch {
            XCTAssertFalse(error is LaunchDetailError)
        }
    }

    func test_fetch_offline_returnsBundledFallbackDetail() async throws {
        let fallback = MockLaunchFallbackDS(
            launch: LaunchDTO(
                id: "l1",
                name: "Fallback Launch",
                dateUtc: "2024-01-01T00:00:00.000Z",
                success: true,
                rocket: "r1",
                upcoming: false,
                details: "Fallback details",
                launchpad: "pad1",
                links: nil,
                cores: nil,
                payloads: ["p1"],
                crew: nil,
                ships: nil,
                capsules: nil
            ),
            rocket: RocketSummary(id: "r1", name: "Fallback Rocket", type: "rocket"),
            launchpad: Launchpad(id: "pad1", name: "Fallback Pad", fullName: nil, locality: nil, region: nil, latitude: nil, longitude: nil)
        )
        let sut = LaunchDetailRepository(
            launchDetailDataSource: MockDetailDS(error: MockRepoError.failed),
            launchpadDataSource: MockLaunchpadDS(launchpad: nil),
            rocketDataSource: MockRocketDS(rocket: nil),
            payloadDataSource: MockPayloadDS(payload: nil),
            crewDataSource: MockCrewDS(crewMember: nil),
            capsuleDataSource: MockCapsuleDS(capsule: nil),
            shipDataSource: MockShipDS(ship: nil),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fallbackDataSource: fallback
        )

        let detail = try await sut.fetchDetail(for: "l1")

        XCTAssertEqual(detail.launch.id, "l1")
        XCTAssertEqual(detail.rocket?.name, "Fallback Rocket")
        XCTAssertEqual(detail.launchpad?.name, "Fallback Pad")
        XCTAssertTrue(detail.isStale)
    }

    func test_fetch_offline_withoutFallback_throwsOfflineUnavailable() async {
        let sut = LaunchDetailRepository(
            launchDetailDataSource: MockDetailDS(error: MockRepoError.failed),
            launchpadDataSource: MockLaunchpadDS(launchpad: nil),
            rocketDataSource: MockRocketDS(rocket: nil),
            payloadDataSource: MockPayloadDS(payload: nil),
            crewDataSource: MockCrewDS(crewMember: nil),
            capsuleDataSource: MockCapsuleDS(capsule: nil),
            shipDataSource: MockShipDS(ship: nil),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fallbackDataSource: nil
        )

        do {
            _ = try await sut.fetchDetail(for: "l1")
            XCTFail("Expected throw")
        } catch {
            XCTAssertTrue(error is LaunchDetailError)
        }
    }
}

private final class MockNetworkMonitor: NetworkMonitorProtocol {
    private let connected: Bool

    init(isConnected: Bool) {
        self.connected = isConnected
    }

    var connectivityPublisher: AnyPublisher<ConnectivityStatus, Never> {
        Just(connected ? .connected : .disconnected).eraseToAnyPublisher()
    }

    var connectionRestoredPublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var connectivityStatus: ConnectivityStatus {
        connected ? .connected : .disconnected
    }

    func isConnected() -> Bool {
        connected
    }
}

private final class MockDetailDS: LaunchDetailRemoteDataSourceProtocol {
    let dto: LaunchDTO?
    let error: Error?

    init(dto: LaunchDTO? = nil, error: Error? = nil) {
        self.dto = dto
        self.error = error
    }

    func fetchLaunch(for launchId: String) async throws -> LaunchDTO {
        if let error { throw error }
        return dto!
    }
}

private final class MockLaunchpadDS: LaunchpadRemoteDataSourceProtocol {
    let launchpad: Launchpad?

    init(launchpad: Launchpad?) {
        self.launchpad = launchpad
    }

    func fetchLaunchpad(for id: String) async throws -> Launchpad {
        guard let launchpad else { throw MockRepoError.failed }
        return launchpad
    }
}

private final class MockRocketDS: RocketDetailRemoteDataSourceProtocol {
    let rocket: RocketSummary?

    init(rocket: RocketSummary?) {
        self.rocket = rocket
    }

    func fetchRocket(for id: String) async throws -> RocketSummary {
        guard let rocket else { throw MockRepoError.failed }
        return rocket
    }
}

private final class MockPayloadDS: PayloadRemoteDataSourceProtocol {
    let payload: Payload?

    init(payload: Payload?) {
        self.payload = payload
    }

    func fetchPayload(for id: String) async throws -> Payload {
        guard let payload else { throw MockRepoError.failed }
        return payload
    }
}

private final class MockCrewDS: CrewRemoteDataSourceProtocol {
    let crewMember: CrewMember?

    init(crewMember: CrewMember?) {
        self.crewMember = crewMember
    }

    func fetchCrewMember(for id: String) async throws -> CrewMember {
        guard let crewMember else { throw MockRepoError.failed }
        return crewMember
    }
}

private final class MockCapsuleDS: CapsuleRemoteDataSourceProtocol {
    let capsule: Capsule?

    init(capsule: Capsule?) {
        self.capsule = capsule
    }

    func fetchCapsule(for id: String) async throws -> Capsule {
        guard let capsule else { throw MockRepoError.failed }
        return capsule
    }
}

private final class MockShipDS: ShipRemoteDataSourceProtocol {
    let ship: Ship?

    init(ship: Ship?) {
        self.ship = ship
    }

    func fetchShip(for id: String) async throws -> Ship {
        guard let ship else { throw MockRepoError.failed }
        return ship
    }
}

private final class MockLaunchFallbackDS: LaunchFallbackDataSourceProtocol {
    let launch: LaunchDTO?
    let rocket: RocketSummary?
    let launchpad: Launchpad?

    init(launch: LaunchDTO?, rocket: RocketSummary?, launchpad: Launchpad?) {
        self.launch = launch
        self.rocket = rocket
        self.launchpad = launchpad
    }

    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) throws -> LaunchPageDTO {
        LaunchPageDTO(docs: launch.map { [$0] } ?? [], hasNextPage: false, nextPage: nil)
    }

    func fetchLaunch(for launchId: String) throws -> LaunchDTO {
        guard let launch else { throw LaunchDetailError.launchNotFound(id: launchId) }
        return launch
    }

    func fetchRocketSummary(for rocketId: String) -> RocketSummary? {
        rocket
    }

    func fetchLaunchpad(for launchpadId: String) -> Launchpad? {
        launchpad
    }
}

private enum MockRepoError: Error {
    case failed
}
