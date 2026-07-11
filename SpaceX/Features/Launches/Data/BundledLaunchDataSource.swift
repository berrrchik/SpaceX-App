import Foundation

protocol LaunchFallbackDataSourceProtocol {
    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) throws -> LaunchPageDTO
    func fetchLaunch(for launchId: String) throws -> LaunchDTO
    func fetchRocketSummary(for rocketId: String) -> RocketSummary?
    func fetchLaunchpad(for launchpadId: String) -> Launchpad?
}

final class BundledLaunchDataSource: LaunchFallbackDataSourceProtocol {
    private let bundle: Bundle
    private let resourceName: String
    private let decoder: JSONDecoder
    private var cachedLaunches: [LaunchDTO]?

    init(
        bundle: Bundle = .main,
        resourceName: String = "launches_fallback",
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) throws -> LaunchPageDTO {
        let launches = try loadLaunches()
            .filter { $0.rocket == rocketId }
            .sorted { $0.dateUtc > $1.dateUtc }

        let safeLimit = max(limit, 1)
        let safePage = max(page, 1)
        let startIndex = (safePage - 1) * safeLimit
        guard startIndex < launches.count else {
            return LaunchPageDTO(docs: [], hasNextPage: false, nextPage: nil)
        }

        let endIndex = min(startIndex + safeLimit, launches.count)
        let docs = Array(launches[startIndex..<endIndex])
        let hasNextPage = endIndex < launches.count
        return LaunchPageDTO(
            docs: docs,
            hasNextPage: hasNextPage,
            nextPage: hasNextPage ? safePage + 1 : nil
        )
    }

    func fetchLaunch(for launchId: String) throws -> LaunchDTO {
        guard let launch = try loadLaunches().first(where: { $0.id == launchId }) else {
            throw LaunchDetailError.launchNotFound(id: launchId)
        }
        return launch
    }

    func fetchRocketSummary(for rocketId: String) -> RocketSummary? {
        rocketSummaries[rocketId]
    }

    func fetchLaunchpad(for launchpadId: String) -> Launchpad? {
        launchpads[launchpadId]
    }

    private func loadLaunches() throws -> [LaunchDTO] {
        if let cachedLaunches {
            return cachedLaunches
        }

        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw NetworkError.emptyResponse
        }

        do {
            let data = try Data(contentsOf: url)
            let launches = try decoder.decode([LaunchDTO].self, from: data)
            cachedLaunches = launches
            return launches
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        } catch {
            throw NetworkError.transport(error)
        }
    }

    private var rocketSummaries: [String: RocketSummary] {
        [
            "5e9d0d95eda69955f709d1eb": RocketSummary(id: "5e9d0d95eda69955f709d1eb", name: "Falcon 1", type: "rocket"),
            "5e9d0d95eda69973a809d1ec": RocketSummary(id: "5e9d0d95eda69973a809d1ec", name: "Falcon 9", type: "rocket"),
            "5e9d0d95eda69974db09d1ed": RocketSummary(id: "5e9d0d95eda69974db09d1ed", name: "Falcon Heavy", type: "rocket"),
            "5e9d0d96eda699382d09d1ee": RocketSummary(id: "5e9d0d96eda699382d09d1ee", name: "Starship", type: "rocket")
        ]
    }

    private var launchpads: [String: Launchpad] {
        [
            "5e9e4502f5090995de566f86": Launchpad(
                id: "5e9e4502f5090995de566f86",
                name: "Kwajalein Atoll",
                fullName: "Omelek Island, Kwajalein Atoll",
                locality: "Omelek Island",
                region: "Marshall Islands",
                latitude: 9.0477206,
                longitude: 167.7431292
            ),
            "5e9e4501f509094ba4566f84": Launchpad(
                id: "5e9e4501f509094ba4566f84",
                name: "CCSFS SLC 40",
                fullName: "Cape Canaveral Space Force Station Space Launch Complex 40",
                locality: "Cape Canaveral",
                region: "Florida",
                latitude: 28.5618571,
                longitude: -80.577366
            ),
            "5e9e4502f509094188566f88": Launchpad(
                id: "5e9e4502f509094188566f88",
                name: "KSC LC 39A",
                fullName: "Kennedy Space Center Historic Launch Complex 39A",
                locality: "Cape Canaveral",
                region: "Florida",
                latitude: 28.6080585,
                longitude: -80.6039558
            ),
            "5e9e4502f509092b78566f87": Launchpad(
                id: "5e9e4502f509092b78566f87",
                name: "VSFB SLC 4E",
                fullName: "Vandenberg Space Force Base Space Launch Complex 4E",
                locality: "Vandenberg Space Force Base",
                region: "California",
                latitude: 34.632093,
                longitude: -120.610829
            ),
            "starbase-orbital-launch-mount": Launchpad(
                id: "starbase-orbital-launch-mount",
                name: "Starbase",
                fullName: "Starbase Orbital Launch Mount",
                locality: "Boca Chica",
                region: "Texas",
                latitude: 25.996,
                longitude: -97.155
            )
        ]
    }
}
