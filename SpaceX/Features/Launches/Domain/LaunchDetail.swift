import Foundation

struct LaunchDetail {
    let launch: Launch
    let rocket: RocketSummary?
    let launchpad: Launchpad?
    let landpad: Landpad?
    let payloads: [Payload]
    let crewMembers: [CrewMember]
    let ships: [Ship]
    let capsules: [Capsule]
    let isStale: Bool

    init(
        launch: Launch,
        rocket: RocketSummary? = nil,
        launchpad: Launchpad?,
        landpad: Landpad? = nil,
        payloads: [Payload] = [],
        crewMembers: [CrewMember] = [],
        ships: [Ship] = [],
        capsules: [Capsule] = [],
        isStale: Bool = false
    ) {
        self.launch = launch
        self.rocket = rocket
        self.launchpad = launchpad
        self.landpad = landpad
        self.payloads = payloads
        self.crewMembers = crewMembers
        self.ships = ships
        self.capsules = capsules
        self.isStale = isStale
    }
}
