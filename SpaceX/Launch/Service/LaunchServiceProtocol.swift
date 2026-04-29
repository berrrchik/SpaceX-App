import Foundation

struct LaunchPage {
    let launches: [LaunchElement]
    let hasNextPage: Bool
    let nextPage: Int?
}

protocol LaunchServiceProtocol {
    func fetchLaunchPage(
        for rocketId: String,
        page: Int,
        completion: @escaping (Result<LaunchPage, Error>) -> Void
    )
}
