import Foundation

protocol LaunchpadRemoteDataSourceProtocol {
    func fetchLaunchpad(for id: String) async throws -> Launchpad
}

final class LaunchpadRemoteDataSource: LaunchpadRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLaunchpad(for id: String) async throws -> Launchpad {
        let dto = try await httpClient.send(LaunchpadEndpoint(id: id))
        return Launchpad(
            id: dto.id,
            name: dto.name,
            fullName: dto.fullName,
            locality: dto.locality,
            region: dto.region,
            latitude: dto.latitude,
            longitude: dto.longitude
        )
    }
}

private struct LaunchpadDTO: Decodable {
    let id: String
    let name: String
    let fullName: String?
    let locality: String?
    let region: String?
    let latitude: Double?
    let longitude: Double?
}

private struct LaunchpadEndpoint: APIEndpoint {
    typealias Response = LaunchpadDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/launchpads/\(id)"
    }
}
