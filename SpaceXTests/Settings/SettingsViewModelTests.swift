import XCTest
@testable import SpaceX

final class SettingsViewModelTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsViewModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        notificationCenter = NotificationCenter()
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        notificationCenter = nil
        suiteName = nil
        super.tearDown()
    }

    func testInitMigratesLegacyDiameterKey() {
        userDefaults.set(true, forKey: "isDiameterft")

        _ = SettingsViewModel(
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        XCTAssertEqual(userDefaults.object(forKey: "isDiameterFt") as? Bool, true)
        XCTAssertNil(userDefaults.object(forKey: "isDiameterft"))
    }

    func testToggleStatePersistsUpdatedValue() {
        let viewModel = SettingsViewModel(
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        viewModel.toggleState(at: 0)

        XCTAssertEqual(viewModel.getToggleStates()[0], true)
        XCTAssertEqual(userDefaults.bool(forKey: "isHeightFt"), true)
    }

    func testSaveSettingsRefreshesOtherObserversThroughNotificationCenter() {
        let firstViewModel = SettingsViewModel(
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )
        let secondViewModel = SettingsViewModel(
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        firstViewModel.toggleState(at: 2)
        firstViewModel.saveSettings()

        XCTAssertEqual(secondViewModel.getToggleStates()[2], true)
    }
}
