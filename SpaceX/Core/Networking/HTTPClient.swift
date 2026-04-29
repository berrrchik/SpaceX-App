import Foundation

protocol HTTPClient {
    func send<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response
}
