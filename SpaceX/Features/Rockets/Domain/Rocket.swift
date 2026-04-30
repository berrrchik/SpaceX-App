import Foundation

struct Rocket: Codable {
    let id: String
    let name: String
    let country: String
    let costPerLaunch: Int
    let firstFlightDate: String
    let height: MeasureSize
    let diameter: MeasureSize
    let mass: MeasureWeight
    let firstStage: FirstStage
    let secondStage: SecondStage
    let payloadWeights: [MeasureWeight]
    let flickrImages: [String]
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
