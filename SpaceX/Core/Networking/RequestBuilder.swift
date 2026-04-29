import Foundation

protocol RequestBuilding {
    func makeURLRequest<E: APIEndpoint>(for endpoint: E) throws -> URLRequest
}

struct RequestBuilder: RequestBuilding {
    private let baseURL: URL
    private let headersProvider: HTTPHeadersProviding

    init(baseURL: URL, headersProvider: HTTPHeadersProviding = DefaultHTTPHeadersProvider()) {
        self.baseURL = baseURL
        self.headersProvider = headersProvider
    }

    func makeURLRequest<E: APIEndpoint>(for endpoint: E) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.cachePolicy = endpoint.cachePolicy.urlRequestCachePolicy

        var mergedHeaders = headersProvider.defaultHeaders
        endpoint.headers.forEach { mergedHeaders[$0.key] = $0.value }
        for (key, value) in mergedHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
