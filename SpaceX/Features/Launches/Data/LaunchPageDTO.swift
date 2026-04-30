import Foundation

struct LaunchPageDTO: Decodable {
    let docs: [LaunchDTO]
    let hasNextPage: Bool
    let nextPage: Int?
}
