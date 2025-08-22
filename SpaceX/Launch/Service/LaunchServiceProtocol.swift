import Foundation

protocol LaunchServiceProtocol {
    func fetchLaunch(completion: @escaping (Result<[LaunchElement], Error>) -> Void)
}
