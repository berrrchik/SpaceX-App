import Foundation

protocol LaunchDetailRemoteDataSourceProtocol {
    func fetchLaunch(for launchId: String) async throws -> LaunchDTO
}

final class LaunchDetailRemoteDataSource: LaunchDetailRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLaunch(for launchId: String) async throws -> LaunchDTO {
        try await httpClient.send(LaunchDetailEndpoint(launchId: launchId))
    }
}

private struct LaunchDetailEndpoint: APIEndpoint {
    typealias Response = LaunchDTO

    let path: String
    let method: HTTPMethod = .get

    init(launchId: String) {
        self.path = "v4/launches/\(launchId)"
    }
}
