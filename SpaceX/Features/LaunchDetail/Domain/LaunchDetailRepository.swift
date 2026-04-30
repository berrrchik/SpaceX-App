import Foundation

protocol LaunchDetailRepositoryProtocol {
    func fetchDetail(for launchId: String) async throws -> LaunchDetail
}

enum LaunchDetailError: Error {
    case invalidData
    case launchNotFound(id: String)
}

final class LaunchDetailRepository: LaunchDetailRepositoryProtocol {
    private let launchDetailDataSource: LaunchDetailRemoteDataSourceProtocol
    private let launchpadDataSource: LaunchpadRemoteDataSourceProtocol
    private let rocketDataSource: RocketDetailRemoteDataSourceProtocol
    private let payloadDataSource: PayloadRemoteDataSourceProtocol
    private let crewDataSource: CrewRemoteDataSourceProtocol
    private let capsuleDataSource: CapsuleRemoteDataSourceProtocol
    private let shipDataSource: ShipRemoteDataSourceProtocol
    private let cacheStore: LaunchCacheStoreProtocol
    private let mapper = LaunchMapper()
    private let logger = AppLogger.make("LaunchDetailRepository")

    init(
        launchDetailDataSource: LaunchDetailRemoteDataSourceProtocol,
        launchpadDataSource: LaunchpadRemoteDataSourceProtocol,
        rocketDataSource: RocketDetailRemoteDataSourceProtocol,
        payloadDataSource: PayloadRemoteDataSourceProtocol,
        crewDataSource: CrewRemoteDataSourceProtocol,
        capsuleDataSource: CapsuleRemoteDataSourceProtocol,
        shipDataSource: ShipRemoteDataSourceProtocol,
        cacheStore: LaunchCacheStoreProtocol
    ) {
        self.launchDetailDataSource = launchDetailDataSource
        self.launchpadDataSource = launchpadDataSource
        self.rocketDataSource = rocketDataSource
        self.payloadDataSource = payloadDataSource
        self.crewDataSource = crewDataSource
        self.capsuleDataSource = capsuleDataSource
        self.shipDataSource = shipDataSource
        self.cacheStore = cacheStore
    }

    func fetchDetail(for launchId: String) async throws -> LaunchDetail {
        logger.debug("Loading detail for launch \(launchId, privacy: .public)")
        do {
            let launchDTO = try await launchDetailDataSource.fetchLaunch(for: launchId)
            guard let launch = mapper.map(launchDTO) else {
                throw LaunchDetailError.invalidData
            }

            var launchpad: Launchpad?
            var rocket: RocketSummary?
            var payloads: [Payload] = []
            var crewMembers: [CrewMember] = []
            var capsules: [Capsule] = []
            var ships: [Ship] = []
            if let launchpadId = launch.launchpadId {
                do {
                    launchpad = try await launchpadDataSource.fetchLaunchpad(for: launchpadId)
                } catch {
                    logger.warning(
                        "Launchpad fetch failed for \(launchpadId, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
            do {
                rocket = try await rocketDataSource.fetchRocket(for: launch.rocketId)
            } catch {
                logger.warning("Rocket fetch failed for \(launch.rocketId, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }

            if !launch.payloadIds.isEmpty {
                payloads = await withTaskGroup(of: Payload?.self, returning: [Payload].self) { group in
                    for payloadId in launch.payloadIds {
                        group.addTask { [payloadDataSource] in
                            try? await payloadDataSource.fetchPayload(for: payloadId)
                        }
                    }

                    var results: [Payload] = []
                    for await payload in group {
                        if let payload {
                            results.append(payload)
                        }
                    }
                    return launch.payloadIds.compactMap { payloadId in
                        results.first(where: { $0.id == payloadId })
                    }
                }
            }
            if !launch.crew.isEmpty {
                crewMembers = await withTaskGroup(of: CrewMember?.self, returning: [CrewMember].self) { group in
                    for crew in launch.crew {
                        group.addTask { [crewDataSource] in
                            try? await crewDataSource.fetchCrewMember(for: crew.crewId)
                        }
                    }

                    var results: [CrewMember] = []
                    for await crew in group {
                        if let crew {
                            results.append(crew)
                        }
                    }
                    return launch.crew.compactMap { launchCrew in
                        results.first(where: { $0.crewId == launchCrew.crewId })
                    }
                }
            }
            if !launch.capsuleIds.isEmpty {
                capsules = await withTaskGroup(of: Capsule?.self, returning: [Capsule].self) { group in
                    for capsuleId in launch.capsuleIds {
                        group.addTask { [capsuleDataSource] in
                            try? await capsuleDataSource.fetchCapsule(for: capsuleId)
                        }
                    }

                    var results: [Capsule] = []
                    for await capsule in group {
                        if let capsule {
                            results.append(capsule)
                        }
                    }
                    return launch.capsuleIds.compactMap { capsuleId in
                        results.first(where: { $0.id == capsuleId })
                    }
                }
            }
            if !launch.shipIds.isEmpty {
                ships = await withTaskGroup(of: Ship?.self, returning: [Ship].self) { group in
                    for shipId in launch.shipIds {
                        group.addTask { [shipDataSource] in
                            try? await shipDataSource.fetchShip(for: shipId)
                        }
                    }

                    var results: [Ship] = []
                    for await ship in group {
                        if let ship {
                            results.append(ship)
                        }
                    }
                    return launch.shipIds.compactMap { shipId in
                        results.first(where: { $0.id == shipId })
                    }
                }
            }

            return LaunchDetail(
                launch: launch,
                rocket: rocket,
                launchpad: launchpad,
                payloads: payloads.isEmpty ? launch.payloadIds.map { Payload(id: $0, name: nil, type: nil, massKg: nil, orbit: nil) } : payloads,
                crewMembers: crewMembers.isEmpty ? launch.crew : crewMembers,
                ships: ships.isEmpty ? launch.shipIds.map { Ship(id: $0, name: nil, model: nil, type: nil, active: nil, homePort: nil, imageURL: nil) } : ships,
                capsules: capsules.isEmpty ? launch.capsuleIds.map { Capsule(id: $0, serial: nil, status: nil, type: nil) } : capsules,
                isStale: false
            )
        } catch {
            logger.warning(
                "Network fetch failed for launch \(launchId, privacy: .public): \(error.localizedDescription, privacy: .public). Trying cache."
            )
            let cachedLaunch = cacheStore
                .allKnownRocketIds()
                .compactMap { cacheStore.load(for: $0) }
                .flatMap { $0 }
                .first { $0.id == launchId }

            guard let cachedLaunch else {
                throw LaunchDetailError.launchNotFound(id: launchId)
            }

            return LaunchDetail(
                launch: cachedLaunch,
                rocket: nil,
                launchpad: nil,
                payloads: cachedLaunch.payloadIds.map { Payload(id: $0, name: nil, type: nil, massKg: nil, orbit: nil) },
                crewMembers: cachedLaunch.crew,
                ships: cachedLaunch.shipIds.map { Ship(id: $0, name: nil, model: nil, type: nil, active: nil, homePort: nil, imageURL: nil) },
                capsules: cachedLaunch.capsuleIds.map { Capsule(id: $0, serial: nil, status: nil, type: nil) },
                isStale: true
            )
        }
    }
}
