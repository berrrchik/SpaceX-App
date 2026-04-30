import Foundation

protocol RocketRepositoryProtocol {
    func fetchRockets() async throws -> [Rocket]
}

final class RocketRepository: RocketRepositoryProtocol {
    private let remoteDataSource: RocketRemoteDataSourceProtocol
    private let cacheStore: RocketCacheStoreProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let mapper: RocketMapper
    private let logger = AppLogger.make("RocketRepository")
    
    init(
        remoteDataSource: RocketRemoteDataSourceProtocol,
        cacheStore: RocketCacheStoreProtocol,
        networkMonitor: NetworkMonitorProtocol,
        mapper: RocketMapper = RocketMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStore = cacheStore
        self.networkMonitor = networkMonitor
        self.mapper = mapper
    }
    
    func fetchRockets() async throws -> [Rocket] {
        let cached = cacheStore.load() ?? []
        if !networkMonitor.isConnected() {
            guard !cached.isEmpty else {
                throw NetworkError.transport(URLError(.notConnectedToInternet))
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
            guard !cached.isEmpty else { throw error }
            logger.warning("Rockets fetch failed, returning cached rockets")
            return cached
        }
    }
}
