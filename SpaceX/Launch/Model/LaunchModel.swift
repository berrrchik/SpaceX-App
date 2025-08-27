import Foundation

struct LaunchElement: Codable {
    let name: String
    let dateUtc: String
    let success: Bool?
    let rocket: String
    
    var getDateUTC: String {
        return dateUtc.formatDate() ?? "-"
    }
}
