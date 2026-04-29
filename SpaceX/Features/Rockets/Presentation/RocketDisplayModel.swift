import Foundation

struct RocketDisplayModel {
    let id: String
    let name: String
    let imageURL: URL?
    
    let firstFlightDate: String
    let country: String
    let costPerLaunch: String
    
    let heightValue: String
    let heightUnit: String
    let diameterValue: String
    let diameterUnit: String
    let massValue: String
    let massUnit: String
    let payloadWeightValue: String
    let payloadWeightUnit: String
    
    let firstStageEngines: String
    let firstStageFuelTons: String
    let firstStageBurnTime: String
    
    let secondStageEngines: String
    let secondStageFuelTons: String
    let secondStageBurnTime: String
}
