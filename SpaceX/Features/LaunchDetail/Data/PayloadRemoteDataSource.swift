import Foundation

protocol PayloadRemoteDataSourceProtocol {
    func fetchPayload(for id: String) async throws -> Payload
}

final class PayloadRemoteDataSource: PayloadRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchPayload(for id: String) async throws -> Payload {
        let dto = try await httpClient.send(PayloadDetailEndpoint(id: id))
        return Payload(
            id: dto.id,
            name: dto.name,
            type: dto.type,
            massKg: dto.massKg,
            orbit: dto.orbit
        )
    }
}

private struct PayloadDetailDTO: Decodable {
    let id: String
    let name: String?
    let type: String?
    let massKg: Double?
    let orbit: String?
}

private struct PayloadDetailEndpoint: APIEndpoint {
    typealias Response = PayloadDetailDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/payloads/\(id)"
    }
}
