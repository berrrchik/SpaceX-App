import Foundation

final class AppContainer {
    private let userDefaults: UserDefaults

    lazy var settingsStore: SettingsStore = UserDefaultsSettingsStore(userDefaults: userDefaults)
    lazy var rocketViewModel = RocketViewModel()
    lazy var launchViewModel = LaunchViewModel()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(settingsStore: settingsStore)
    }
}
