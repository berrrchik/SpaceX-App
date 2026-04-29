import Foundation
import OSLog

final class URLSessionHTTPClient: HTTPClient {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SpaceX",
        category: "HTTPClient"
    )

    private let session: URLSession
    private let requestBuilder: RequestBuilding
    private let decoder: JSONDecoder
    private let retryPolicy: NetworkRetryPolicy

    init(
        session: URLSession = .shared,
        requestBuilder: RequestBuilding,
        decoder: JSONDecoder = JSONDecoder(),
        retryPolicy: NetworkRetryPolicy = .default
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoder = decoder
        self.retryPolicy = retryPolicy
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func send<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        let request = try requestBuilder.makeURLRequest(for: endpoint)

        var attempt = 1
        while true {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.emptyResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.server(statusCode: httpResponse.statusCode, data: data)
                }

                do {
                    return try decoder.decode(E.Response.self, from: data)
                } catch {
                    throw NetworkError.decoding(error)
                }
            } catch {
                let normalizedError = normalizeError(error)
                guard shouldRetry(normalizedError, attempt: attempt) else {
                    throw normalizedError
                }

                let delay = retryPolicy.delay(forAttempt: attempt)
                Self.logger.debug(
                    "Retrying failed request \(request.httpMethod ?? "-", privacy: .public) \(request.url?.absoluteString ?? "-", privacy: .public) attempt=\(attempt, privacy: .public) delay=\(delay, privacy: .public)s"
                )
                if delay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                attempt += 1
            }
        }
    }

    private func normalizeError(_ error: Error) -> Error {
        if let networkError = error as? NetworkError {
            return networkError
        }
        return NetworkError.transport(error)
    }

    private func shouldRetry(_ error: Error, attempt: Int) -> Bool {
        guard attempt < retryPolicy.maxAttempts else { return false }

        guard let networkError = error as? NetworkError,
              case .transport(let transportError) = networkError,
              let urlError = transportError as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
