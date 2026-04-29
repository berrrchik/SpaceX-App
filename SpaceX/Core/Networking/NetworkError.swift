import Foundation

enum NetworkError: Error {
    case invalidURL
    case transport(Error)
    case server(statusCode: Int, data: Data?)
    case emptyResponse
    case decoding(Error)
}
