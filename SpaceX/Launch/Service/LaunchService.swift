import Alamofire
import Foundation

class LaunchService: LaunchServiceProtocol {
    private let endpoint = "https://api.spacexdata.com/v4/launches"
    func fetchLaunch(completion: @escaping (Result<[LaunchElement], any Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        AF.request(endpoint)
            .validate()
            .responseDecodable(of: [LaunchElement].self, decoder: decoder) { response in
                switch response.result {
                case .success(let launch):
                    completion(.success(launch))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
