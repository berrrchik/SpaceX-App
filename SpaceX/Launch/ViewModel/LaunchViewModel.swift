import Foundation

class LaunchViewModel {
    private let launchApiService: LaunchServiceProtocol
    private var launches: [LaunchElement] = []
    private var isLoading = false
    
    init(launchApiService: LaunchServiceProtocol = LaunchService()) {
        self.launchApiService = launchApiService
    }
    
    func numberOfLaunches(for rocketId: String) -> Int {
        launches.filter {$0.rocket == rocketId}.count
    }
    
    func launch(at index: Int, for rocketId: String) -> LaunchElement? {
        let filteredLaunches = launches.filter {$0.rocket == rocketId}
        let sortedLaunches = filteredLaunches.sorted {$0.dateUtc > $1.dateUtc}
        
        guard index < sortedLaunches.count else {return nil}
        return sortedLaunches[index]
    }
    
    func loadAllLaunches(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isLoading else {return}
        
        isLoading = true
        
        launchApiService.fetchLaunch { [weak self] result in
            
            defer { //устанавливает isloadind = false после выполнения вне зависимости от успеха или ошбки
                self?.isLoading = false
            }
            
            switch result {
            case .success(let launches):
                self?.launches = launches
                completion(.success(()))
            case .failure(let error):
                print("Ошибка при загрузке запусков: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
    }
    
    func fetchLaunches(rocketId: String, completion: @escaping (Result<[LaunchElement], Error>) -> Void) {
        guard !launches.isEmpty else {
            loadAllLaunches { [weak self] result in
                switch result {
                case .success:
                    let filteredLaunches = self?.launches.filter {$0.rocket == rocketId} ?? []
                    let sortedLaunches = filteredLaunches.sorted {$0.dateUtc > $1.dateUtc}
                    completion(.success(sortedLaunches))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        let filteredLaunches = launches.filter {$0.rocket == rocketId}
        let sortedLaunches = filteredLaunches.sorted {$0.dateUtc > $1.dateUtc}
        completion(.success(sortedLaunches))
    }
    
}
