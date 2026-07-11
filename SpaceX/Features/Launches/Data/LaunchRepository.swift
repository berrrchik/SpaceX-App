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
    private let fallbackDataSource: LaunchFallbackDataSourceProtocol?
    private let mapper: LaunchMapper
    private let pageSize: Int
    private let logger = AppLogger.make("LaunchRepository")
    
    init(
        remoteDataSource: LaunchRemoteDataSourceProtocol,
        cacheStore: LaunchCacheStoreProtocol,
        networkMonitor: NetworkMonitorProtocol,
        fallbackDataSource: LaunchFallbackDataSourceProtocol? = nil,
        mapper: LaunchMapper = LaunchMapper(),
        pageSize: Int = 20
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStore = cacheStore
        self.networkMonitor = networkMonitor
        self.fallbackDataSource = fallbackDataSource
        self.mapper = mapper
        self.pageSize = pageSize
    }
    
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        let cached = cacheStore.load(for: rocketID) ?? []
        let hasCachedSnapshot = cacheStore.allKnownRocketIds().contains(rocketID)
        if !networkMonitor.isConnected() {
            guard hasCachedSnapshot else {
                return try loadFallbackLaunches(
                    for: rocketID,
                    page: 1,
                    originalError: NetworkError.transport(URLError(.notConnectedToInternet))
                )
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
            guard hasCachedSnapshot else {
                return try loadFallbackLaunches(for: rocketID, page: 1, originalError: error)
            }
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
                "Device offline for rocket \(rocketID, privacy: .public); trying bundled fallback page \(page, privacy: .public)"
            )
            return try loadFallbackLaunches(
                for: rocketID,
                page: page,
                originalError: NetworkError.transport(URLError(.notConnectedToInternet))
            )
        }
        do {
            let pageDTO = try await remoteDataSource.fetchLaunchPage(for: rocketID, page: page, limit: pageSize)
            let result = mapper.map(pageDTO)
            let existing = cacheStore.load(for: rocketID) ?? []
            let merged = existing + result.launches.filter { launch in
                !existing.contains { $0.id == launch.id }
            }
            cacheStore.save(merged, for: rocketID)
            return result
        } catch {
            logger.warning(
                "Next page fetch failed for rocket \(rocketID, privacy: .public); trying bundled fallback page \(page, privacy: .public)"
            )
            let result = try loadFallbackLaunches(for: rocketID, page: page, originalError: error)
            let existing = cacheStore.load(for: rocketID) ?? []
            let merged = existing + result.launches.filter { launch in
                !existing.contains { $0.id == launch.id }
            }
            cacheStore.save(merged, for: rocketID)
            return result
        }
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        cacheStore.load(for: rocketID) ?? []
    }

    private func loadFallbackLaunches(for rocketID: String, page: Int, originalError: Error) throws -> LaunchPageResult {
        guard let fallbackDataSource else { throw originalError }

        do {
            let pageDTO = try fallbackDataSource.fetchLaunchPage(for: rocketID, page: page, limit: pageSize)
            var result = mapper.map(pageDTO)
            result = LaunchPageResult(
                launches: result.launches,
                hasNextPage: result.hasNextPage,
                nextPage: result.nextPage,
                isStale: true
            )
            if page == 1 {
                let allFallbackDTO = try fallbackDataSource.fetchLaunchPage(
                    for: rocketID,
                    page: 1,
                    limit: Int.max
                )
                cacheStore.save(mapper.map(allFallbackDTO.docs), for: rocketID)
            }
            logger.warning("Launch fetch failed with empty cache, returning bundled fallback for rocket \(rocketID, privacy: .public)")
            return result
        } catch {
            logger.error("Bundled launch fallback failed: \(error.localizedDescription, privacy: .public)")
            throw originalError
        }
    }
}
