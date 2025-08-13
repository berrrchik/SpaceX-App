import Foundation

class LaunchViewModel {
    private let launchApiService: LaunchServiceProtocol
    private var launches: [LaunchElement] = []
    
    init(launchApiService: LaunchServiceProtocol = LaunchService()) {
        self.launchApiService = launchApiService
    }
    
    func launch(at index: Int) -> LaunchElement? {
        guard index < launches.count else {return nil}
        return launches[index]
    }
    
    func fetchLaunches(rocketId: String, completion: @escaping (Result<[LaunchElement], Error>) -> Void) {
        launchApiService.fetchLaunch { [weak self] result in
            switch result {
            case .success(let launches):
                self?.launches = launches
                var filteredLaunches = launches.filter {$0.rocket == rocketId}
                completion(.success(filteredLaunches))
            case .failure(let error):
                print("Ошибка при загрузке данных")
                completion(.failure(error))
            }
        }
    }
    
}
