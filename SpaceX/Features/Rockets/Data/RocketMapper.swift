import Foundation

struct RocketMapper {
    func map(_ dto: RocketDTO) -> Rocket {
        Rocket(
            id: dto.id,
            name: dto.name,
            country: dto.country,
            costPerLaunch: dto.costPerLaunch,
            firstFlightDate: dto.firstFlight.formatDate() ?? "-",
            height: MeasureSize(
                meters: dto.height.meters,
                feet: dto.height.feet
            ),
            diameter: MeasureSize(
                meters: dto.diameter.meters,
                feet: dto.diameter.feet
            ),
            mass: MeasureWeight(
                kg: dto.mass.kg,
                lb: dto.mass.lb
            ),
            firstStage: FirstStage(
                engines: dto.firstStage.engines,
                fuelAmountTons: dto.firstStage.fuelAmountTons,
                burnTimeSec: dto.firstStage.burnTimeSec
            ),
            secondStage: SecondStage(
                engines: dto.secondStage.engines,
                fuelAmountTons: dto.secondStage.fuelAmountTons,
                burnTimeSec: dto.secondStage.burnTimeSec
            ),
            payloadWeights: dto.payloadWeights.map {
                MeasureWeight(kg: $0.kg, lb: $0.lb)
            },
            flickrImages: dto.flickrImages
        )
    }
    
    func map(_ dtos: [RocketDTO]) -> [Rocket] {
        dtos.map { map($0) }
    }
}
