import Foundation

protocol LaunchRepositoryProtocol {
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult
    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult
}

final class LaunchRepository: LaunchRepositoryProtocol {
    private let remoteDataSource: LaunchRemoteDataSourceProtocol
    private let mapper: LaunchMapper
    private let pageSize: Int
    
    init(
        remoteDataSource: LaunchRemoteDataSourceProtocol,
        mapper: LaunchMapper = LaunchMapper(),
        pageSize: Int = 20
    ) {
        self.remoteDataSource = remoteDataSource
        self.mapper = mapper
        self.pageSize = pageSize
    }
    
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        let pageDTO = try await remoteDataSource.fetchLaunchPage(for: rocketID, page: 1, limit: pageSize)
        return mapper.map(pageDTO)
    }
    
    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        let pageDTO = try await remoteDataSource.fetchLaunchPage(for: rocketID, page: page, limit: pageSize)
        return mapper.map(pageDTO)
    }
}
