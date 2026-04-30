import Foundation

final class URLSessionHTTPClient: HTTPClient {
    private static let logger = AppLogger.make("HTTPClient")

    private let sessionConfiguration: URLSessionConfiguration
    private let requestBuilder: RequestBuilding
    private let decoder: JSONDecoder
    private let retryPolicy: NetworkRetryPolicy

    init(
        session: URLSession = .shared,
        requestBuilder: RequestBuilding,
        decoder: JSONDecoder = JSONDecoder(),
        retryPolicy: NetworkRetryPolicy = .default
    ) {
        // Store only the configuration so we can create a fresh URLSession
        // for every request. iOS keeps an Alt-Svc (HTTP/3 alternative-service)
        // cache per URLSession. Reusing a long-lived session causes iOS to
        // try QUIC for subsequent requests even after the QUIC connection
        // to api.spacexdata.com has gone stale, producing -1005 errors.
        // Creating a new session each time prevents this — matching SpaceDash's
        // per-request session strategy which is known to work reliably.
        self.sessionConfiguration = session.configuration
        self.requestBuilder = requestBuilder
        self.decoder = decoder
        self.retryPolicy = retryPolicy
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func send<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        let request = try requestBuilder.makeURLRequest(for: endpoint)
        var attempt = 1

        while true {
            // Fresh session per attempt — no QUIC Alt-Svc cache inherited from
            // previous requests. Mirrors SpaceDash's new-session-per-request approach.
            let session = URLSession(configuration: sessionConfiguration)

            do {
                let (data, response) = try await session.data(for: request)
                session.finishTasksAndInvalidate()

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.emptyResponse
                }

                Self.logger.debug(
                    "Response \(httpResponse.statusCode, privacy: .public) for \(request.url?.absoluteString ?? "-", privacy: .public)"
                )

                guard (200...299).contains(httpResponse.statusCode) else {
                    let preview = String(data: data, encoding: .utf8).map { String($0.prefix(500)) } ?? "<non-utf8>"
                    Self.logger.error(
                        "Server error \(httpResponse.statusCode, privacy: .public) for \(request.url?.absoluteString ?? "-", privacy: .public): \(preview, privacy: .public)"
                    )
                    throw NetworkError.server(statusCode: httpResponse.statusCode, data: data)
                }

                do {
                    return try decoder.decode(E.Response.self, from: data)
                } catch {
                    let preview = String(data: data, encoding: .utf8).map { String($0.prefix(500)) } ?? "<non-utf8>"
                    Self.logger.error(
                        "Decoding failed for \(request.url?.absoluteString ?? "-", privacy: .public): \(preview, privacy: .public)"
                    )
                    throw NetworkError.decoding(error)
                }
            } catch {
                session.finishTasksAndInvalidate()
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

    // MARK: - Private

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
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
