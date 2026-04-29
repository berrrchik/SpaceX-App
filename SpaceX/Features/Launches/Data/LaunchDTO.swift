import Foundation

struct LaunchDTO: Codable {
    let name: String
    let dateUtc: String
    let success: Bool?
    let rocket: String
}
