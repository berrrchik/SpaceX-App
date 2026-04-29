import XCTest
@testable import SpaceX

final class SettingsViewModelTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var settingsStore: SettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsViewModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        settingsStore = UserDefaultsSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        settingsStore = nil
        suiteName = nil
        super.tearDown()
    }

    func testToggleStateUpdatesLocalStateUntilSave() {
        let viewModel = SettingsViewModel(settingsStore: settingsStore)

        viewModel.toggleState(at: 0)

        XCTAssertEqual(viewModel.getToggleStates()[0], true)
        XCTAssertEqual(userDefaults.bool(forKey: "isHeightFt"), false)
    }

    func testSaveSettingsPersistsUpdatedValueToStore() {
        let viewModel = SettingsViewModel(settingsStore: settingsStore)

        viewModel.toggleState(at: 0)
        viewModel.saveSettings()

        XCTAssertEqual(userDefaults.bool(forKey: "isHeightFt"), true)
    }

    func testSaveSettingsRefreshesOtherObserversThroughStore() {
        let firstViewModel = SettingsViewModel(settingsStore: settingsStore)
        let secondViewModel = SettingsViewModel(settingsStore: settingsStore)

        firstViewModel.toggleState(at: 2)
        firstViewModel.saveSettings()

        XCTAssertEqual(secondViewModel.getToggleStates()[2], true)
    }
}
