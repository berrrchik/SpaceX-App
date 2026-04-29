import Foundation
import OSLog

class LaunchService: LaunchServiceProtocol {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "LaunchService"
    )

    private let httpClient: HTTPClient
    private let pageSize = 20

    convenience init() {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.spacexdata.com")!)
        let client = URLSessionHTTPClient(requestBuilder: builder)
        self.init(httpClient: client)
    }

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        completion: @escaping (Result<LaunchPage, any Error>) -> Void
    ) {
        let startedAt = Date()

        Self.logger.debug("Starting launches query request for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) limit=\(self.pageSize, privacy: .public)")

        let endpoint = LaunchesQueryEndpoint(rocketID: rocketId, page: page, limit: pageSize)

        Task {
            do {
                let launchResponse = try await self.httpClient.send(endpoint)
                let duration = Date().timeIntervalSince(startedAt)

                Self.logger.debug(
                    "Launches query page succeeded. rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) duration=\(duration, privacy: .public)s pageCount=\(launchResponse.docs.count, privacy: .public) hasNext=\(launchResponse.hasNextPage, privacy: .public)"
                )

                let launchPage = LaunchPage(
                    launches: launchResponse.docs,
                    hasNextPage: launchResponse.hasNextPage,
                    nextPage: launchResponse.nextPage
                )

                DispatchQueue.main.async {
                    completion(.success(launchPage))
                }
            } catch {
                let duration = Date().timeIntervalSince(startedAt)
                Self.logger.error(
                    "Launches query page failed. rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) duration=\(duration, privacy: .public)s error=\(error.localizedDescription, privacy: .public)"
                )
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
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

private struct LaunchQueryResponse: Decodable {
    let docs: [LaunchElement]
    let hasNextPage: Bool
    let nextPage: Int?
}

private struct LaunchesQueryEndpoint: APIEndpoint {
    typealias Response = LaunchQueryResponse

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
