import Foundation

protocol RocketRepositoryProtocol {
    func fetchRockets() async throws -> [Rocket]
}

final class RocketRepository: RocketRepositoryProtocol {
    private let remoteDataSource: RocketRemoteDataSourceProtocol
    private let mapper: RocketMapper
    
    init(
        remoteDataSource: RocketRemoteDataSourceProtocol,
        mapper: RocketMapper = RocketMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mapper = mapper
    }
    
    func fetchRockets() async throws -> [Rocket] {
        let dtos = try await remoteDataSource.fetchRockets()
        return mapper.map(dtos)
    }
}
