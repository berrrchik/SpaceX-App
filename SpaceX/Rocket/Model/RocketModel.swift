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
