import Alamofire
import Foundation
import OSLog

class LaunchService: LaunchServiceProtocol {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "LaunchService"
    )

    private let endpoint = "https://api.spacexdata.com/v4/launches/query"
    private let pageSize = 20
    private let maxRetryCount = 1

    func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        completion: @escaping (Result<LaunchPage, any Error>) -> Void
    ) {
        fetchLaunchPage(for: rocketId, page: page, retryCount: 0, completion: completion)
    }

    private func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        retryCount: Int,
        completion: @escaping (Result<LaunchPage, any Error>) -> Void
    ) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let startedAt = Date()

        let request = LaunchQueryRequest(
            query: LaunchQuery(rocket: rocketId),
            options: LaunchQueryOptions(
                pagination: true,
                limit: pageSize,
                page: page,
                sort: ["date_utc": "desc"],
                select: ["name", "date_utc", "success", "rocket"]
            )
        )

        Self.logger.debug("Starting launches query request to \(self.endpoint, privacy: .public) for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) limit=\(self.pageSize, privacy: .public)")

        AF.request(
            endpoint,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .responseDecodable(of: LaunchQueryResponse.self, decoder: decoder) { response in
            let duration = Date().timeIntervalSince(startedAt)
            let statusCode = response.response?.statusCode ?? -1
            let dataSize = response.data?.count ?? 0

            switch response.result {
            case .success(let launchResponse):
                Self.logger.debug(
                    "Launches query page succeeded. rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) status=\(statusCode, privacy: .public) duration=\(duration, privacy: .public)s bytes=\(dataSize, privacy: .public) pageCount=\(launchResponse.docs.count, privacy: .public) hasNext=\(launchResponse.hasNextPage, privacy: .public)"
                )
                completion(
                    .success(
                        LaunchPage(
                            launches: launchResponse.docs,
                            hasNextPage: launchResponse.hasNextPage,
                            nextPage: launchResponse.nextPage
                        )
                    )
                )

            case .failure(let error):
                Self.logger.error(
                    "Launches query page failed. rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public) status=\(statusCode, privacy: .public) duration=\(duration, privacy: .public)s bytes=\(dataSize, privacy: .public) retry=\(retryCount, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                )

                guard retryCount < self.maxRetryCount else {
                    completion(.failure(error))
                    return
                }

                Self.logger.debug("Retrying launches query page for rocket id=\(rocketId, privacy: .public) page=\(page, privacy: .public)")
                self.fetchLaunchPage(
                    for: rocketId,
                    page: page,
                    retryCount: retryCount + 1,
                    completion: completion
                )
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
