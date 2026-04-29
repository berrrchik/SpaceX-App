import Foundation

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

class SettingsViewModel {
    enum SettingsKey: String, CaseIterable {
        case isHeightFt
        case isDiameterFt
        case isMassLb
        case isPayloadWeightLb
    }
    
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private var toggleStates: [Bool]
    
    init(
        userDefaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter

        Self.migrateLegacyKeysIfNeeded(in: userDefaults)
        toggleStates = Self.keys.map { key in
            userDefaults.bool(forKey: key.rawValue)
        }
        setupObservers()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    func getToggleStates() -> [Bool] {
        return toggleStates
    }
    
    func toggleState(at index: Int) {
        guard toggleStates.indices.contains(index) else { return }
        toggleStates[index].toggle()
        saveToggleStates()
    }
    
    func saveSettings() {
        saveToggleStates()
        notificationCenter.post(name: .settingsDidChange, object: nil)
    }
    
    private func saveToggleStates() {
        for (index, state) in toggleStates.enumerated() {
            userDefaults.set(state, forKey: Self.keys[index].rawValue)
        }
    }
    
    private func refreshToggleStates() {
        toggleStates = Self.keys.map { key in
            userDefaults.bool(forKey: key.rawValue)
        }
    }
    
    private func setupObservers() {
        notificationCenter.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    private static func migrateLegacyKeysIfNeeded(in userDefaults: UserDefaults) {
        let legacyKey = "isDiameterft"
        let newKey = SettingsKey.isDiameterFt.rawValue

        guard userDefaults.object(forKey: newKey) == nil,
              let legacyValue = userDefaults.object(forKey: legacyKey) as? Bool else {
            return
        }

        userDefaults.set(legacyValue, forKey: newKey)
        userDefaults.removeObject(forKey: legacyKey)
    }
    
    @objc private func settingsDidChange() {
        refreshToggleStates()
    }
}

private extension SettingsViewModel {
    static let keys = SettingsKey.allCases
}
