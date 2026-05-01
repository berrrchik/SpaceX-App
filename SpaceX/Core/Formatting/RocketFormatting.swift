import Foundation

protocol RocketFormatting {
    func formatForDisplay(
        _ rocket: Rocket,
        preferences: MeasurementPreference,
        dateFormatter: DateFormatting
    ) -> RocketDisplayModel
}

final class DefaultRocketFormatter: RocketFormatting {
    func formatForDisplay(
        _ rocket: Rocket,
        preferences: MeasurementPreference,
        dateFormatter: DateFormatting
    ) -> RocketDisplayModel {
        let imageURL = rocket.flickrImages.first.flatMap { URL(string: $0) }
        
        let heightValue: String
        let heightUnit: String
        if preferences.usesImperial(for: .height), let feet = rocket.height.feet {
            heightValue = String(format: "%.1f", feet)
            heightUnit = "ft"
        } else if let meters = rocket.height.meters {
            heightValue = String(format: "%.1f", meters)
            heightUnit = "m"
        } else {
            heightValue = "-"
            heightUnit = "m"
        }
        
        let diameterValue: String
        let diameterUnit: String
        if preferences.usesImperial(for: .diameter), let feet = rocket.diameter.feet {
            diameterValue = String(format: "%.1f", feet)
            diameterUnit = "ft"
        } else if let meters = rocket.diameter.meters {
            diameterValue = String(format: "%.1f", meters)
            diameterUnit = "m"
        } else {
            diameterValue = "-"
            diameterUnit = "m"
        }
        
        let massValue: String
        let massUnit: String
        if preferences.usesImperial(for: .mass) {
            massValue = formatNumber(rocket.mass.lb)
            massUnit = "lb"
        } else {
            massValue = formatNumber(rocket.mass.kg)
            massUnit = "kg"
        }
        
        let payloadWeightValue: String
        let payloadWeightUnit: String
        if let firstPayload = rocket.payloadWeights.first {
            if preferences.usesImperial(for: .payloadWeight) {
                payloadWeightValue = formatNumber(firstPayload.lb)
                payloadWeightUnit = "lb"
            } else {
                payloadWeightValue = formatNumber(firstPayload.kg)
                payloadWeightUnit = "kg"
            }
        } else {
            payloadWeightValue = "-"
            payloadWeightUnit = "kg"
        }
        
        return RocketDisplayModel(
            id: rocket.id,
            name: rocket.name,
            imageURL: imageURL,
            firstFlightDate: dateFormatter.format(rocket.firstFlightDate),
            country: rocket.country,
            costPerLaunch: formatCurrency(rocket.costPerLaunch),
            heightValue: heightValue,
            heightUnit: heightUnit,
            diameterValue: diameterValue,
            diameterUnit: diameterUnit,
            massValue: massValue,
            massUnit: massUnit,
            payloadWeightValue: payloadWeightValue,
            payloadWeightUnit: payloadWeightUnit,
            firstStageEngines: String(rocket.firstStage.engines),
            firstStageFuelTons: String(rocket.firstStage.fuelAmountTons),
            firstStageBurnTime: rocket.firstStage.burnTimeSec.map { String($0) } ?? "0",
            secondStageEngines: String(rocket.secondStage.engines),
            secondStageFuelTons: String(rocket.secondStage.fuelAmountTons),
            secondStageBurnTime: rocket.secondStage.burnTimeSec.map { String($0) } ?? "0"
        )
    }
    
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    private func formatCurrency(_ value: Int) -> String {
        let millions = Double(value) / 1_000_000.0
        if millions >= 1000 {
            let billions = millions / 1000.0
            return String(format: "$%.1fB", billions)
        } else {
            return String(format: "$%.0fM", millions)
        }
    }
}
