import Foundation

struct RocketSummary {
    let id: String
    let name: String
    let type: String?
}

protocol RocketDetailRemoteDataSourceProtocol {
    func fetchRocket(for id: String) async throws -> RocketSummary
}

final class RocketDetailRemoteDataSource: RocketDetailRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchRocket(for id: String) async throws -> RocketSummary {
        let dto = try await httpClient.send(RocketDetailEndpoint(id: id))
        return RocketSummary(id: dto.id, name: dto.name, type: dto.type)
    }
}

private struct RocketDetailDTO: Decodable {
    let id: String
    let name: String
    let type: String?
}

private struct RocketDetailEndpoint: APIEndpoint {
    typealias Response = RocketDetailDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/rockets/\(id)"
    }
}
