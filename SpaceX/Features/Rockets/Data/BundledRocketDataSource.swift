import Foundation

protocol RocketFallbackDataSourceProtocol {
    func fetchRockets() throws -> [RocketDTO]
}

final class BundledRocketDataSource: RocketFallbackDataSourceProtocol {
    private let bundle: Bundle
    private let resourceName: String
    private let decoder: JSONDecoder

    init(
        bundle: Bundle = .main,
        resourceName: String = "rockets_fallback",
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchRockets() throws -> [RocketDTO] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw NetworkError.emptyResponse
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([RocketDTO].self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        } catch {
            throw NetworkError.transport(error)
        }
    }
}
