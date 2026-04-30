import Foundation

protocol LandpadRemoteDataSourceProtocol {
    func fetchLandpad(for id: String) async throws -> Landpad
}

final class LandpadRemoteDataSource: LandpadRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLandpad(for id: String) async throws -> Landpad {
        let dto = try await httpClient.send(LandpadEndpoint(id: id))
        return Landpad(
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

private struct LandpadDTO: Decodable {
    let id: String
    let name: String
    let fullName: String?
    let locality: String?
    let region: String?
    let latitude: Double?
    let longitude: Double?
}

private struct LandpadEndpoint: APIEndpoint {
    typealias Response = LandpadDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/landpads/\(id)"
    }
}
