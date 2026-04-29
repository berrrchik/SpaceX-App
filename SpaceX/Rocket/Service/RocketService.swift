import Foundation

class RocketService: RocketServiceProtocol {
    private let httpClient: HTTPClient

    convenience init() {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.spacexdata.com")!)
        let client = URLSessionHTTPClient(requestBuilder: builder)
        self.init(httpClient: client)
    }

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchRockets(completion: @escaping (Result<[RocketElement], any Error>) -> Void) {
        Task {
            do {
                let rockets = try await httpClient.send(RocketsEndpoint())
                DispatchQueue.main.async {
                    completion(.success(rockets))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

private struct RocketsEndpoint: APIEndpoint {
    typealias Response = [RocketElement]

    let path = "v4/rockets"
    let method: HTTPMethod = .get
    let cachePolicy: HTTPCachePolicy = .returnCacheDataElseLoad
}
