import XCTest
@testable import SpaceX

final class RocketCacheStoreTests: XCTestCase {
    private static let suiteName = "com.test.rocketCacheStore"

    private var testDefaults: UserDefaults!
    private var sut: UserDefaultsRocketCacheStore!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.suiteName)
        sut = UserDefaultsRocketCacheStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        sut = nil
        testDefaults = nil
        super.tearDown()
    }

    func test_save_thenLoad_returnsIdenticalRockets() {
        let rockets = [Self.makeRocket(id: "r1"), Self.makeRocket(id: "r2")]
        sut.save(rockets)

        let loaded = sut.load()

        XCTAssertEqual(loaded?.map(\.id), ["r1", "r2"])
    }

    func test_load_missingKey_returnsNil() {
        XCTAssertNil(sut.load())
    }

    func test_save_overwritesExistingEntry() {
        sut.save([Self.makeRocket(id: "old")])
        sut.save([Self.makeRocket(id: "new")])

        let loaded = sut.load()
        XCTAssertEqual(loaded?.map(\.id), ["new"])
    }

    func test_clear_removesCachedEntry() {
        sut.save([Self.makeRocket(id: "r1")])
        sut.clear()
        XCTAssertNil(sut.load())
    }

    func test_load_corruptData_returnsNil() {
        testDefaults.set("bad".data(using: .utf8), forKey: "rockets_all")
        XCTAssertNil(sut.load())
    }
}

private extension RocketCacheStoreTests {
    static func makeRocket(id: String) -> Rocket {
        Rocket(
            id: id,
            name: "Rocket \(id)",
            country: "US",
            costPerLaunch: 100,
            firstFlightDate: "01.01.2020",
            height: MeasureSize(meters: 1, feet: 3),
            diameter: MeasureSize(meters: 1, feet: 3),
            mass: MeasureWeight(kg: 100, lb: 220),
            firstStage: FirstStage(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            secondStage: SecondStage(engines: 1, fuelAmountTons: 1, burnTimeSec: 1),
            payloadWeights: [MeasureWeight(kg: 10, lb: 22)],
            flickrImages: []
        )
    }
}
