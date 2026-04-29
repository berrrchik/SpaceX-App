import Foundation

protocol APIEndpoint {
    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var cachePolicy: HTTPCachePolicy { get }
}

extension APIEndpoint {
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
    var cachePolicy: HTTPCachePolicy { .useProtocolCachePolicy }
}
