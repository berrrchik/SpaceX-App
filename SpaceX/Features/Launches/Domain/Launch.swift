import Foundation

struct Launch: Codable {
    let id: String
    let name: String
    let dateUtc: String
    let formattedDate: String
    let success: Bool?
    let rocketId: String
    let launchpadId: String?
    let upcoming: Bool
    let details: String?
    let links: LaunchLinks?
    let cores: [Core]
    let payloadIds: [String]
    let crew: [CrewMember]
    let shipIds: [String]
    let capsuleIds: [String]

    init(
        id: String,
        name: String,
        dateUtc: String,
        formattedDate: String,
        success: Bool?,
        rocketId: String,
        launchpadId: String? = nil,
        upcoming: Bool = false,
        details: String? = nil,
        links: LaunchLinks? = nil,
        cores: [Core] = [],
        payloadIds: [String] = [],
        crew: [CrewMember] = [],
        shipIds: [String] = [],
        capsuleIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.dateUtc = dateUtc
        self.formattedDate = formattedDate
        self.success = success
        self.rocketId = rocketId
        self.launchpadId = launchpadId
        self.upcoming = upcoming
        self.details = details
        self.links = links
        self.cores = cores
        self.payloadIds = payloadIds
        self.crew = crew
        self.shipIds = shipIds
        self.capsuleIds = capsuleIds
    }
}
