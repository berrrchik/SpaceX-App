import Foundation

protocol RocketRepositoryProtocol {
    func fetchRockets() async throws -> [Rocket]
}

final class RocketRepository: RocketRepositoryProtocol {
    private let remoteDataSource: RocketRemoteDataSourceProtocol
    private let cacheStore: RocketCacheStoreProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let fallbackDataSource: RocketFallbackDataSourceProtocol?
    private let mapper: RocketMapper
    private let logger = AppLogger.make("RocketRepository")
    
    init(
        remoteDataSource: RocketRemoteDataSourceProtocol,
        cacheStore: RocketCacheStoreProtocol,
        networkMonitor: NetworkMonitorProtocol,
        fallbackDataSource: RocketFallbackDataSourceProtocol? = nil,
        mapper: RocketMapper = RocketMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStore = cacheStore
        self.networkMonitor = networkMonitor
        self.fallbackDataSource = fallbackDataSource
        self.mapper = mapper
    }
    
    func fetchRockets() async throws -> [Rocket] {
        let cached = cacheStore.load() ?? []
        if !networkMonitor.isConnected() {
            guard !cached.isEmpty else {
                return try loadFallbackRockets(
                    originalError: NetworkError.transport(URLError(.notConnectedToInternet))
                )
            }
            logger.warning("Device offline, returning cached rockets")
            return cached
        }
        do {
            let dtos = try await remoteDataSource.fetchRockets()
            let rockets = mapper.map(dtos)
            cacheStore.save(rockets)
            return rockets
        } catch {
            guard !cached.isEmpty else {
                return try loadFallbackRockets(originalError: error)
            }
            logger.warning("Rockets fetch failed, returning cached rockets")
            return cached
        }
    }

    private func loadFallbackRockets(originalError: Error) throws -> [Rocket] {
        guard let fallbackDataSource else { throw originalError }

        do {
            let dtos = try fallbackDataSource.fetchRockets()
            let rockets = mapper.map(dtos)
            cacheStore.save(rockets)
            logger.warning("Rockets fetch failed with empty cache, returning bundled fallback")
            return rockets
        } catch {
            logger.error("Bundled rocket fallback failed: \(error.localizedDescription, privacy: .public)")
            throw originalError
        }
    }
}
