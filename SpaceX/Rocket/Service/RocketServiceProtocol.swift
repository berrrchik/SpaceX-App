import Foundation

protocol RocketServiceProtocol {
    func fetchRockets(completion: @escaping (Result<[RocketElement], Error>) -> Void)
}
