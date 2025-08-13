import Foundation

class RocketViewModel {
    private let rocketApiService: RocketServiceProtocol
    private var rockets: [RocketElement] = []
    
    var numberOfRockets: Int {
        return rockets.count
    }
    
    init(rocketApiService: RocketServiceProtocol = RocketService()) {
        self.rocketApiService = rocketApiService
    }
    
//    func rocketName(at index: Int) -> String? {
//        guard index < rockets.count else {return nil}
//        return rockets[index].name
//    }
    
    func rocket(at index: Int) -> RocketElement? {
        guard index < rockets.count else {return nil}
        return rockets[index]
    }
    
    func fetchRockets(completion: @escaping (Result<Void, Error>) -> Void) {
        rocketApiService.fetchRockets { [weak self] result in
            switch result {
            case .success(let rockets):
                self?.rockets = rockets
                completion(.success(()))
            case .failure(let error):
                print("Ошибка при загрузке данных")
                completion(.failure(error))
            }
        }
    }
}
