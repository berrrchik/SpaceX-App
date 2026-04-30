import Foundation

protocol CapsuleRemoteDataSourceProtocol {
    func fetchCapsule(for id: String) async throws -> Capsule
}

final class CapsuleRemoteDataSource: CapsuleRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchCapsule(for id: String) async throws -> Capsule {
        let dto = try await httpClient.send(CapsuleDetailEndpoint(id: id))
        return Capsule(
            id: dto.id,
            serial: dto.serial,
            status: dto.status,
            type: dto.type
        )
    }
}

private struct CapsuleDetailDTO: Decodable {
    let id: String
    let serial: String?
    let status: String?
    let type: String?
}

private struct CapsuleDetailEndpoint: APIEndpoint {
    typealias Response = CapsuleDetailDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/capsules/\(id)"
    }
}
