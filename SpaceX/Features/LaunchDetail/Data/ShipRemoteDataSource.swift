import Foundation

protocol ShipRemoteDataSourceProtocol {
    func fetchShip(for id: String) async throws -> Ship
}

final class ShipRemoteDataSource: ShipRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchShip(for id: String) async throws -> Ship {
        let dto = try await httpClient.send(ShipDetailEndpoint(id: id))
        return Ship(
            id: dto.id,
            name: dto.name,
            model: dto.model,
            type: dto.type,
            active: dto.active,
            homePort: dto.homePort,
            imageURL: dto.image.flatMap(URL.init(string:))
        )
    }
}

private struct ShipDetailDTO: Decodable {
    let id: String
    let name: String?
    let model: String?
    let type: String?
    let active: Bool?
    let homePort: String?
    let image: String?
}

private struct ShipDetailEndpoint: APIEndpoint {
    typealias Response = ShipDetailDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/ships/\(id)"
    }
}
