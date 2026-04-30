import Foundation

protocol LaunchRemoteDataSourceProtocol {
    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) async throws -> LaunchPageDTO
}

final class LaunchRemoteDataSource: LaunchRemoteDataSourceProtocol {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetchLaunchPage(for rocketId: String, page: Int, limit: Int) async throws -> LaunchPageDTO {
        let endpoint = LaunchesQueryEndpoint(rocketID: rocketId, page: page, limit: limit)
        return try await httpClient.send(endpoint)
    }
}

private struct LaunchQueryRequest: Encodable {
    let query: LaunchQueryPayload
    let options: LaunchQueryOptions
}

private struct LaunchQueryPayload: Encodable {
    let rocket: String
}

private struct LaunchQueryOptions: Encodable {
    let pagination: Bool
    let limit: Int
    let page: Int
    let sort: [String: String]
    let select: [String]
}

private struct LaunchesQueryEndpoint: APIEndpoint {
    typealias Response = LaunchPageDTO
    
    let path = "v4/launches/query"
    let method: HTTPMethod = .post
    let body: Data?
    let headers: [String: String] = [
        "Content-Type": "application/json"
    ]
    let cachePolicy: HTTPCachePolicy = .reloadIgnoringLocalCacheData
    
    init(rocketID: String, page: Int, limit: Int) {
        let request = LaunchQueryRequest(
            query: LaunchQueryPayload(rocket: rocketID),
            options: LaunchQueryOptions(
                pagination: true,
                limit: limit,
                page: page,
                sort: ["date_utc": "desc"],
                select: [
                    "id",
                    "name",
                    "date_utc",
                    "success",
                    "rocket",
                    "upcoming",
                    "details",
                    "launchpad",
                    "links",
                    "cores",
                    "payloads",
                    "crew",
                    "ships",
                    "capsules"
                ]
            )
        )
        self.body = try? JSONEncoder().encode(request)
    }
}
