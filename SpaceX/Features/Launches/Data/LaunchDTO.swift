import Foundation

struct LaunchDTO: Decodable {
    let id: String?
    let name: String
    let dateUtc: String
    let success: Bool?
    let rocket: String
    let upcoming: Bool?
    let details: String?
    let launchpad: String?
    let links: LaunchLinksDTO?
    let cores: [CoreDTO]?
    let payloads: [String]?
    let crew: [CrewMemberDTO]?
    let ships: [String]?
    let capsules: [String]?
}

struct LaunchLinksDTO: Decodable {
    let wikipedia: String?
    let article: String?
    let webcast: String?
}

struct CoreDTO: Decodable {
    let core: String?
    let reused: Bool?
    let landingSuccess: Bool?
}

struct CrewMemberDTO: Decodable {
    let crew: String?
    let role: String?
}
