import Foundation

struct RocketElement: Codable {
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
        let payloadWeightIsLb = UserDefaults.standard.bool(forKey: "isPayloadWeightLb")
        return payloadWeightIsLb ? ("\(payloadWeights[0].lb)", "Полезная нагрузка, lb") : ("\(payloadWeights[0].kg)", "Полезная нагрузка, kg")
    }
    
    var getFirstFlightDate: String {
        return firstFlight.formatDate() ?? "-"
    }
}

struct MeasureSize: Codable {
    let meters: Double?
    let feet: Double?
}

struct MeasureWeight: Codable {
    let kg: Int
    let lb: Int
}

struct FirstStage: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}

struct SecondStage: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}
