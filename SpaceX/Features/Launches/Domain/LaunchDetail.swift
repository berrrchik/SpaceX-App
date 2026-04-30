import Foundation

struct LaunchDetail {
    let launch: Launch
    let launchpad: Launchpad?
    let landpad: Landpad?
    let payloads: [Payload]
    let ships: [Ship]
    let capsules: [Capsule]
}
