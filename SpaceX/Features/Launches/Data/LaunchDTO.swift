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
    let patch: LaunchPatchDTO?
    let wikipedia: String?
    let article: String?
    let webcast: String?
}

struct LaunchPatchDTO: Decodable {
    let small: String?
    let large: String?
}

struct CoreDTO: Decodable {
    let core: String?
    let reused: Bool?
    let landingSuccess: Bool?
}

struct CrewMemberDTO: Decodable {
    let crew: String?
    let role: String?

    init(crew: String?, role: String?) {
        self.crew = crew
        self.role = role
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let crewId = try? singleValue.decode(String.self) {
            self.init(crew: crewId, role: nil)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let crew = try container.decodeIfPresent(String.self, forKey: .crew)
            ?? container.decodeIfPresent(String.self, forKey: .id)
        let role = try container.decodeIfPresent(String.self, forKey: .role)
        self.init(crew: crew, role: role)
    }

    private enum CodingKeys: String, CodingKey {
        case crew
        case role
        case id
    }
}
