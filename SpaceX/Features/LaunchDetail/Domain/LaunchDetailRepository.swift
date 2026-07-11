import Foundation

protocol LaunchDetailRepositoryProtocol {
    func fetchDetail(for launchId: String) async throws -> LaunchDetail
}

enum LaunchDetailError: Error {
    case invalidData
    case launchNotFound(id: String)
    case offlineUnavailable
}

final class LaunchDetailRepository: LaunchDetailRepositoryProtocol {
    private let launchDetailDataSource: LaunchDetailRemoteDataSourceProtocol
    private let launchpadDataSource: LaunchpadRemoteDataSourceProtocol
    private let rocketDataSource: RocketDetailRemoteDataSourceProtocol
    private let payloadDataSource: PayloadRemoteDataSourceProtocol
    private let crewDataSource: CrewRemoteDataSourceProtocol
    private let capsuleDataSource: CapsuleRemoteDataSourceProtocol
    private let shipDataSource: ShipRemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let fallbackDataSource: LaunchFallbackDataSourceProtocol?
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
        networkMonitor: NetworkMonitorProtocol,
        fallbackDataSource: LaunchFallbackDataSourceProtocol? = nil
    ) {
        self.launchDetailDataSource = launchDetailDataSource
        self.launchpadDataSource = launchpadDataSource
        self.rocketDataSource = rocketDataSource
        self.payloadDataSource = payloadDataSource
        self.crewDataSource = crewDataSource
        self.capsuleDataSource = capsuleDataSource
        self.shipDataSource = shipDataSource
        self.networkMonitor = networkMonitor
        self.fallbackDataSource = fallbackDataSource
    }

    func fetchDetail(for launchId: String) async throws -> LaunchDetail {
        logger.debug("Loading detail for launch \(launchId, privacy: .public)")
        if !networkMonitor.isConnected() {
            logger.warning("No network for launch detail \(launchId, privacy: .public). Trying bundled fallback.")
            return try loadFallbackDetail(for: launchId, originalError: LaunchDetailError.offlineUnavailable)
        }
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
            if !networkMonitor.isConnected() {
                return try loadFallbackDetail(for: launchId, originalError: LaunchDetailError.offlineUnavailable)
            }
            logger.warning(
                "Network fetch failed for launch \(launchId, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return try loadFallbackDetail(for: launchId, originalError: error)
        }
    }

    private func loadFallbackDetail(for launchId: String, originalError: Error) throws -> LaunchDetail {
        guard let fallbackDataSource else { throw originalError }

        do {
            let launchDTO = try fallbackDataSource.fetchLaunch(for: launchId)
            guard let launch = mapper.map(launchDTO) else {
                throw LaunchDetailError.invalidData
            }

            logger.warning("Returning bundled fallback detail for launch \(launchId, privacy: .public)")
            return LaunchDetail(
                launch: launch,
                rocket: fallbackDataSource.fetchRocketSummary(for: launch.rocketId),
                launchpad: launch.launchpadId.flatMap { fallbackDataSource.fetchLaunchpad(for: $0) },
                payloads: launch.payloadIds.map(makeFallbackPayload),
                crewMembers: launch.crew,
                ships: launch.shipIds.map(makeFallbackShip),
                capsules: launch.capsuleIds.map { Capsule(id: $0, serial: nil, status: nil, type: nil) },
                isStale: true
            )
        } catch {
            logger.error("Bundled detail fallback failed: \(error.localizedDescription, privacy: .public)")
            throw originalError
        }
    }

    private func makeFallbackPayload(from value: String) -> Payload {
        let parts = value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        if parts.count >= 4 {
            return Payload(
                id: parts[0],
                name: parts[0].nilIfEmpty,
                type: parts[1].nilIfEmpty ?? fallbackPayloadType(for: parts[0]),
                massKg: parseMassKg(parts[2]),
                orbit: parts[3].nilIfEmpty
            )
        }
        return Payload(
            id: value,
            name: value,
            type: fallbackPayloadType(for: value),
            massKg: nil,
            orbit: nil
        )
    }

    private func parseMassKg(_ value: String) -> Double? {
        guard value.localizedCaseInsensitiveContains("kg") else { return nil }
        let kilogramsPart = value.components(separatedBy: "kg").first ?? value
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let numericString = kilogramsPart.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map(String.init)
            .joined()
            .replacingOccurrences(of: ",", with: "")
        return Double(numericString)
    }

    private func fallbackPayloadType(for value: String) -> String {
        let lowercased = value.lowercased()
        if lowercased.contains("dragon") || lowercased.contains("crew") {
            return "Spacecraft"
        }
        if lowercased.contains("roadster") {
            return "Satellite"
        }
        return "Satellite"
    }

    private func makeFallbackShip(from value: String) -> Ship {
        let parts = value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else {
            return Ship(id: value, name: value, model: nil, type: nil, active: nil, homePort: nil, imageURL: nil)
        }
        return Ship(
            id: parts[0],
            name: parts[0],
            model: nil,
            type: parts[1],
            active: nil,
            homePort: parts[2],
            imageURL: nil
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
