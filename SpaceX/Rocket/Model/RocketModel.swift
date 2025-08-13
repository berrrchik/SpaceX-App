import Foundation

class RocketElement: Codable {
    
    let height: MeasureSize
    let diameter: MeasureSize
    let mass: MeasureWeight
    
    let firstStage: FirstStage
    let secondStage: SecondStage
    
    let payloadWeights: [MeasureWeight]
    
    let flickrImages: [String]
    
    let name: String
    let costPerLaunch: Int
    let firstFlight: String
    let country: String
    
    let id: String
    
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
        case id
    }
}

class MeasureSize: Codable {
    let meters: Double?
    let feet: Double?
    
    init(meters: Double?, feet: Double?) {
        self.meters = meters
        self.feet = feet
    }
}

class MeasureWeight: Codable {
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

//class PayloadWeight: Codable {
//    let kg: Double
//    let lb: Double
//    
//    init(kg: Double, lb: Double) {
//        self.kg = kg
//        self.lb = lb
//    }
//}
