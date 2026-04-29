import Foundation

class RocketViewModel {
    private let rocketRepository: RocketRepositoryProtocol
    private var rockets: [Rocket] = []
    
    var numberOfRockets: Int {
        return rockets.count
    }
    
    init(rocketRepository: RocketRepositoryProtocol) {
        self.rocketRepository = rocketRepository
    }
    
    func rocket(at index: Int) -> Rocket? {
        guard index < rockets.count else { return nil }
        return rockets[index]
    }
    
    func fetchRockets(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let rockets = try await rocketRepository.fetchRockets()
                DispatchQueue.main.async { [weak self] in
                    self?.rockets = rockets
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
