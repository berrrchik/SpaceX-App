import XCTest
@testable import SpaceX

final class UserDefaultsSettingsStoreTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsSettingsStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testInitMigratesLegacyDiameterKey() {
        userDefaults.set(true, forKey: "isDiameterft")

        _ = UserDefaultsSettingsStore(userDefaults: userDefaults)

        XCTAssertEqual(userDefaults.object(forKey: "isDiameterFt") as? Bool, true)
        XCTAssertNil(userDefaults.object(forKey: "isDiameterft"))
    }

    func testUpdateMeasurementPreferencePersistsAllSettings() {
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults)
        let preference = MeasurementPreference(toggleStates: [true, true, false, true])

        store.updateMeasurementPreference(preference)

        XCTAssertEqual(userDefaults.bool(forKey: "isHeightFt"), true)
        XCTAssertEqual(userDefaults.bool(forKey: "isDiameterFt"), true)
        XCTAssertEqual(userDefaults.bool(forKey: "isMassLb"), false)
        XCTAssertEqual(userDefaults.bool(forKey: "isPayloadWeightLb"), true)
    }

    func testUpdateMeasurementPreferenceNotifiesObservers() {
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults)
        let observer = StoreObserverSpy()

        store.addObserver(observer)
        store.updateMeasurementPreference(MeasurementPreference(toggleStates: [false, true, false, false]))

        XCTAssertEqual(observer.receivedPreferences.count, 1)
        XCTAssertEqual(observer.receivedPreferences.first?.usesImperial(for: .diameter), true)
    }
}

private final class StoreObserverSpy: SettingsStoreObserver {
    private(set) var receivedPreferences: [MeasurementPreference] = []

    func settingsStore(_ settingsStore: SettingsStore, didUpdate preference: MeasurementPreference) {
        receivedPreferences.append(preference)
    }
}
