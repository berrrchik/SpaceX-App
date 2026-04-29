import Foundation

protocol RocketRemoteDataSourceProtocol {
    func fetchRockets() async throws -> [RocketDTO]
}

final class RocketRemoteDataSource: RocketRemoteDataSourceProtocol {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetchRockets() async throws -> [RocketDTO] {
        try await httpClient.send(RocketsEndpoint())
    }
}

private struct RocketsEndpoint: APIEndpoint {
    typealias Response = [RocketDTO]
    
    let path = "v4/rockets"
    let method: HTTPMethod = .get
    let cachePolicy: HTTPCachePolicy = .returnCacheDataElseLoad
}
