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
    let query: LaunchQuery
    let options: LaunchQueryOptions
}

private struct LaunchQuery: Encodable {
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
            query: LaunchQuery(rocket: rocketID),
            options: LaunchQueryOptions(
                pagination: true,
                limit: limit,
                page: page,
                sort: ["date_utc": "desc"],
                select: ["name", "date_utc", "success", "rocket"]
            )
        )
        self.body = try? JSONEncoder().encode(request)
    }
}
