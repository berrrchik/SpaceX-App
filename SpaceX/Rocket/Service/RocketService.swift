import Alamofire
import Foundation

class RocketService: RocketServiceProtocol {
    private let endpoint = "https://api.spacexdata.com/v4/rockets"
    func fetchRockets(completion: @escaping (Result<[RocketElement], any Error>) -> Void) {
        AF.request(endpoint)
            .validate()
            .responseDecodable(of: [RocketElement].self) { response in
                switch response.result {
                case .success(let rockets):
                    completion(.success(rockets))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
