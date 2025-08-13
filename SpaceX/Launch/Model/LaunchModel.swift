import Foundation

class LaunchElement: Codable {
    let name: String
    let dateUTC: String
    let success: Bool?
    let rocket: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case dateUTC = "date_utc"
        case success
        case rocket
    }
    
    init(name: String, dateUTC: String, success: Bool?, rocket: String) {
        self.name = name
        self.dateUTC = dateUTC
        self.success = success
        self.rocket = rocket
    }
}

class RocketLaunch: Codable {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

class RocketWithLaunches {
    let rocket: RocketLaunch
    var launches: [LaunchElement]
    
    init(rocket: RocketLaunch, launches: [LaunchElement]) {
        self.rocket = rocket
        self.launches = launches
    }
}
