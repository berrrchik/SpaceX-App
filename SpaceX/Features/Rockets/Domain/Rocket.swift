import Foundation

struct Rocket {
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

struct MeasureSize {
    let meters: Double?
    let feet: Double?
}

struct MeasureWeight {
    let kg: Int
    let lb: Int
}

struct FirstStage {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}

struct SecondStage {
    let engines: Int
    let fuelAmountTons: Double
    let burnTimeSec: Int?
}
