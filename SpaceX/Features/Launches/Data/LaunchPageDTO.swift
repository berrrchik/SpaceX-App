import Foundation

struct LaunchPageDTO: Codable {
    let docs: [LaunchDTO]
    let hasNextPage: Bool
    let nextPage: Int?
}
