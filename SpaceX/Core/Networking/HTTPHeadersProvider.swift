import Foundation

protocol HTTPHeadersProviding {
    var defaultHeaders: [String: String] { get }
}

struct DefaultHTTPHeadersProvider: HTTPHeadersProviding {
    var defaultHeaders: [String: String] {
        [
            "Accept": "application/json"
        ]
    }
}
