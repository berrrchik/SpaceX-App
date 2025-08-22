import Alamofire
import Foundation

class LaunchService: LaunchServiceProtocol {
    private let endpoint = "https://api.spacexdata.com/v4/launches"
    func fetchLaunch(completion: @escaping (Result<[LaunchElement], any Error>) -> Void) {
        AF.request(endpoint)
            .validate()
            .responseDecodable(of: [LaunchElement].self) { response in
                switch response.result {
                case .success(let launch):
                    completion(.success(launch))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
