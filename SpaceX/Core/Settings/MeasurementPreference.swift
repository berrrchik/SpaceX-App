import Foundation

enum MeasurementSetting: Int, CaseIterable {
    case height
    case diameter
    case mass
    case payloadWeight

    var storageKey: String {
        switch self {
        case .height:
            return "isHeightFt"
        case .diameter:
            return "isDiameterFt"
        case .mass:
            return "isMassLb"
        case .payloadWeight:
            return "isPayloadWeightLb"
        }
    }
}

struct MeasurementPreference: Equatable {
    private let usesImperialBySetting: [MeasurementSetting: Bool]

    init(usesImperialBySetting: [MeasurementSetting: Bool] = [:]) {
        var normalized: [MeasurementSetting: Bool] = [:]
        for setting in MeasurementSetting.allCases {
            normalized[setting] = usesImperialBySetting[setting] ?? false
        }
        self.usesImperialBySetting = normalized
    }

    init(toggleStates: [Bool]) {
        var valuesBySetting: [MeasurementSetting: Bool] = [:]
        for (index, setting) in MeasurementSetting.allCases.enumerated() {
            valuesBySetting[setting] = toggleStates.indices.contains(index) ? toggleStates[index] : false
        }
        self.init(usesImperialBySetting: valuesBySetting)
    }

    func usesImperial(for setting: MeasurementSetting) -> Bool {
        usesImperialBySetting[setting] ?? false
    }

    func toggleStates() -> [Bool] {
        MeasurementSetting.allCases.map { usesImperial(for: $0) }
    }
}
