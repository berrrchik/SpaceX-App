import Foundation

protocol CrewRemoteDataSourceProtocol {
    func fetchCrewMember(for id: String) async throws -> CrewMember
}

final class CrewRemoteDataSource: CrewRemoteDataSourceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchCrewMember(for id: String) async throws -> CrewMember {
        let dto = try await httpClient.send(CrewDetailEndpoint(id: id))
        return CrewMember(
            crewId: dto.id,
            role: nil,
            name: dto.name,
            agency: dto.agency
        )
    }
}

private struct CrewDetailDTO: Decodable {
    let id: String
    let name: String?
    let agency: String?
}

private struct CrewDetailEndpoint: APIEndpoint {
    typealias Response = CrewDetailDTO

    let path: String
    let method: HTTPMethod = .get

    init(id: String) {
        self.path = "v4/crew/\(id)"
    }
}
