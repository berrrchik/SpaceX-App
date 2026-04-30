import Foundation

struct CrewMember: Codable {
    let crewId: String
    let role: String?
    let name: String?
    let agency: String?

    init(crewId: String, role: String?, name: String? = nil, agency: String? = nil) {
        self.crewId = crewId
        self.role = role
        self.name = name
        self.agency = agency
    }
}
