import XCTest
@testable import SpaceX

final class RocketFormattingTests: XCTestCase {
    func testFormatForDisplayUsesMetricValuesByDefault() {
        let formatter = DefaultRocketFormatter()
        let rocket = Self.makeRocket()
        let dateFormatter = MockDateFormatter(result: "formatted-date")
        let preference = MeasurementPreference(usesImperialBySetting: [:])

        let display = formatter.formatForDisplay(
            rocket,
            preferences: preference,
            dateFormatter: dateFormatter
        )

        XCTAssertEqual(display.heightUnit, "m")
        XCTAssertEqual(display.diameterUnit, "m")
        XCTAssertEqual(display.massUnit, "kg")
        XCTAssertEqual(display.payloadWeightUnit, "kg")
        XCTAssertEqual(display.firstFlightDate, "formatted-date")
        XCTAssertEqual(dateFormatter.receivedInput, "2006-03-24")
    }

    func testFormatForDisplayUsesImperialValuesWhenEnabled() {
        let formatter = DefaultRocketFormatter()
        let rocket = Self.makeRocket()
        let dateFormatter = MockDateFormatter(result: "formatted-date")
        let preference = MeasurementPreference(
            usesImperialBySetting: [
                .height: true,
                .diameter: true,
                .mass: true,
                .payloadWeight: true
            ]
        )

        let display = formatter.formatForDisplay(
            rocket,
            preferences: preference,
            dateFormatter: dateFormatter
        )

        XCTAssertEqual(display.heightUnit, "ft")
        XCTAssertEqual(display.diameterUnit, "ft")
        XCTAssertEqual(display.massUnit, "lb")
        XCTAssertEqual(display.payloadWeightUnit, "lb")
    }

    func testFormatForDisplayFormatsCurrencyInMillionsAndBillions() {
        let formatter = DefaultRocketFormatter()
        let dateFormatter = MockDateFormatter(result: "formatted-date")

        let millionDisplay = formatter.formatForDisplay(
            Self.makeRocket(costPerLaunch: 7_000_000),
            preferences: MeasurementPreference(),
            dateFormatter: dateFormatter
        )
        XCTAssertEqual(millionDisplay.costPerLaunch, "$7M")

        let billionDisplay = formatter.formatForDisplay(
            Self.makeRocket(costPerLaunch: 1_200_000_000),
            preferences: MeasurementPreference(),
            dateFormatter: dateFormatter
        )
        XCTAssertEqual(billionDisplay.costPerLaunch, "$1.2B")
    }

    func testFormatForDisplayUsesDashWhenPayloadIsMissing() {
        let formatter = DefaultRocketFormatter()
        let dateFormatter = MockDateFormatter(result: "formatted-date")
        let rocket = Self.makeRocket(payloadWeights: [])

        let display = formatter.formatForDisplay(
            rocket,
            preferences: MeasurementPreference(),
            dateFormatter: dateFormatter
        )

        XCTAssertEqual(display.payloadWeightValue, "-")
        XCTAssertEqual(display.payloadWeightUnit, "kg")
    }

    private static func makeRocket(
        costPerLaunch: Int = 7_000_000,
        payloadWeights: [MeasureWeight] = [MeasureWeight(kg: 22_800, lb: 50_265)]
    ) -> Rocket {
        Rocket(
            id: "falcon9",
            name: "Falcon 9",
            country: "Republic of the Marshall Islands",
            costPerLaunch: costPerLaunch,
            firstFlightDate: "2006-03-24",
            height: MeasureSize(meters: 70, feet: 229.6),
            diameter: MeasureSize(meters: 3.7, feet: 12.0),
            mass: MeasureWeight(kg: 549_054, lb: 1_207_920),
            firstStage: FirstStage(engines: 9, fuelAmountTons: 385, burnTimeSec: 162),
            secondStage: SecondStage(engines: 1, fuelAmountTons: 90, burnTimeSec: 397),
            payloadWeights: payloadWeights,
            flickrImages: ["https://example.com/f9.jpg"]
        )
    }
}

private final class MockDateFormatter: DateFormatting {
    let result: String
    private(set) var receivedInput: String?

    init(result: String) {
        self.result = result
    }

    func format(_ dateString: String) -> String {
        receivedInput = dateString
        return result
    }
}
