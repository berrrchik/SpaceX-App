import Foundation

protocol LaunchRepositoryProtocol {
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult
    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult
    func fetchAllCachedLaunches(for rocketID: String) -> [Launch]
}

final class LaunchRepository: LaunchRepositoryProtocol {
    private let remoteDataSource: LaunchRemoteDataSourceProtocol
    private let cacheStore: LaunchCacheStoreProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let mapper: LaunchMapper
    private let pageSize: Int
    private let logger = AppLogger.make("LaunchRepository")
    
    init(
        remoteDataSource: LaunchRemoteDataSourceProtocol,
        cacheStore: LaunchCacheStoreProtocol,
        networkMonitor: NetworkMonitorProtocol,
        mapper: LaunchMapper = LaunchMapper(),
        pageSize: Int = 20
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStore = cacheStore
        self.networkMonitor = networkMonitor
        self.mapper = mapper
        self.pageSize = pageSize
    }
    
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        let cached = cacheStore.load(for: rocketID) ?? []
        let hasCachedSnapshot = cacheStore.allKnownRocketIds().contains(rocketID)
        if !networkMonitor.isConnected() {
            guard hasCachedSnapshot else {
                throw NetworkError.transport(URLError(.notConnectedToInternet))
            }
            logger.warning("Device offline for rocket \(rocketID, privacy: .public); returning cached launches")
            return LaunchPageResult(
                launches: cached,
                hasNextPage: false,
                nextPage: nil,
                isStale: true
            )
        }
        do {
            let pageDTO = try await remoteDataSource.fetchLaunchPage(for: rocketID, page: 1, limit: pageSize)
            let result = mapper.map(pageDTO)
            cacheStore.save(result.launches, for: rocketID)
            return result
        } catch {
            guard hasCachedSnapshot else { throw error }
            logger.warning("Initial fetch failed for rocket \(rocketID, privacy: .public); returning cached launches")
            return LaunchPageResult(
                launches: cached,
                hasNextPage: false,
                nextPage: nil,
                isStale: true
            )
        }
    }
    
    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        if !networkMonitor.isConnected() {
            logger.warning(
                "Device offline for rocket \(rocketID, privacy: .public); skipping next page \(page, privacy: .public)"
            )
            return LaunchPageResult(
                launches: [],
                hasNextPage: false,
                nextPage: nil,
                isStale: true
            )
        }
        let pageDTO = try await remoteDataSource.fetchLaunchPage(for: rocketID, page: page, limit: pageSize)
        let result = mapper.map(pageDTO)
        let existing = cacheStore.load(for: rocketID) ?? []
        let merged = existing + result.launches.filter { launch in
            !existing.contains { $0.id == launch.id }
        }
        cacheStore.save(merged, for: rocketID)
        return result
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        cacheStore.load(for: rocketID) ?? []
    }
}
