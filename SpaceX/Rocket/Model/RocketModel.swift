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
    
    var getPayloadWeight: (String, String) {
        let payloadWeightIsLb = UserDefaults.standard.bool(forKey: "payloadWeightIsLb")
        
        if payloadWeightIsLb {
            return ("\(payloadWeights[0].lb)", "Полезная нагрузка, lb")
        } else {
            return ("\(payloadWeights[0].kg)", "Полезная нагрузка, kg")
        }
    }
    
    var getFirstFlightDate: String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd MMM, yyyy"
        
        if let date = dateFormatterGet.date(from: firstFlight) {
            return dateFormatterPrint.string(from: date)
        } else {
            return "-"
        }
    }
    
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
