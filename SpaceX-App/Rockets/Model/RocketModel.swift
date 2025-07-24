import Foundation

class RocketElement: Codable {
    let height: Diameter
    let diameter: Diameter
    let mass: Mass
    let firstStage: FirstStage
    let secondStage: SecondStage
    let payloadWeights: [PayloadWeight]
    let flickrImages: [String]
    let name: String
    let costPerLaunch: Int
    let firstFlight: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case height, diameter, mass
        case firstStage = "first_stage"
        case secondStage = "second_stage"
        case payloadWeights = "payload_weights"
        case flickrImages = "flickr_images"
        case name
        case costPerLaunch = "cost_per_launch"
        case firstFlight = "first_flight"
        case country
    }
}

class Diameter: Codable {
    let meters: Double?
    let feet: Double?
    
    init(meters: Double?, feet: Double?) {
        self.meters = meters
        self.feet = feet
    }
}

class Mass: Codable {
    let kg: Int
    let lb: Int
    
    init(kg: Int, lb: Int) {
        self.kg = kg
        self.lb = lb
    }
}

class FirstStage: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSEC: Int?
    
    enum CodingKeys: String, CodingKey {
        case engines
        case fuelAmountTons = "fuel_amount_tons"
        case burnTimeSEC = "burn_time_sec"
    }
    
    init(engines: Int, fuelAmountTons: Double, burnTimeSEC: Int?) {
        self.engines = engines
        self.fuelAmountTons = fuelAmountTons
        self.burnTimeSEC = burnTimeSEC
    }
}

class SecondStage: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSEC: Int?
    
    enum CodingKeys: String, CodingKey {
        case engines
        case fuelAmountTons = "fuel_amount_tons"
        case burnTimeSEC = "burn_time_sec"
    }
    
    init(engines: Int, fuelAmountTons: Double, burnTimeSEC: Int?) {
        self.engines = engines
        self.fuelAmountTons = fuelAmountTons
        self.burnTimeSEC = burnTimeSEC
    }
}

class PayloadWeight: Codable {
    let id: String
    let name: String
    let kg: Int
    let lb: Int
    
    init(id: String, name: String, kg: Int, lb: Int) {
        self.id = id
        self.name = name
        self.kg = kg
        self.lb = lb
    }
}
