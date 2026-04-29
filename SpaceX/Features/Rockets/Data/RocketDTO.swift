import Foundation

struct RocketDTO: Codable {
    let height: MeasureSizeDTO
    let diameter: MeasureSizeDTO
    let mass: MeasureWeightDTO
    let firstStage: FirstStageDTO
    let secondStage: SecondStageDTO
    let payloadWeights: [MeasureWeightDTO]
    let flickrImages: [String]
    let name: String
    let costPerLaunch: Int
    let firstFlight: String
    let country: String
    let id: String
}

struct MeasureSizeDTO: Codable {
    let meters: Double?
    let feet: Double?
}

struct MeasureWeightDTO: Codable {
    let kg: Int
    let lb: Int
}

struct FirstStageDTO: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}

struct SecondStageDTO: Codable {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}
