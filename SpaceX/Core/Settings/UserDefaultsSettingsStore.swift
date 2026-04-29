import Foundation

final class UserDefaultsSettingsStore: SettingsStore {
    private struct LegacyKeyMigration {
        let oldKey: String
        let newKey: String
    }

    private let userDefaults: UserDefaults
    private let observers = NSHashTable<AnyObject>.weakObjects()
    private var currentPreference: MeasurementPreference

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        Self.migrateLegacyKeysIfNeeded(in: userDefaults)
        self.currentPreference = Self.loadPreference(from: userDefaults)
    }

    var measurementPreference: MeasurementPreference {
        currentPreference
    }

    func updateMeasurementPreference(_ preference: MeasurementPreference) {
        currentPreference = preference
        persist(preference)
        notifyObservers()
    }

    func addObserver(_ observer: SettingsStoreObserver) {
        observers.add(observer)
    }

    func removeObserver(_ observer: SettingsStoreObserver) {
        observers.remove(observer)
    }

    private func persist(_ preference: MeasurementPreference) {
        for setting in MeasurementSetting.allCases {
            userDefaults.set(preference.usesImperial(for: setting), forKey: setting.storageKey)
        }
    }

    private func notifyObservers() {
        for observer in observers.allObjects {
            guard let observer = observer as? SettingsStoreObserver else { continue }
            observer.settingsStore(self, didUpdate: currentPreference)
        }
    }

    private static func migrateLegacyKeysIfNeeded(in userDefaults: UserDefaults) {
        let migrations = [
            LegacyKeyMigration(oldKey: "isDiameterft", newKey: MeasurementSetting.diameter.storageKey)
        ]

        for migration in migrations {
            guard userDefaults.object(forKey: migration.newKey) == nil,
                  let legacyValue = userDefaults.object(forKey: migration.oldKey) as? Bool else {
                continue
            }

            userDefaults.set(legacyValue, forKey: migration.newKey)
            userDefaults.removeObject(forKey: migration.oldKey)
        }
    }

    private static func loadPreference(from userDefaults: UserDefaults) -> MeasurementPreference {
        let valuesBySetting = Dictionary(uniqueKeysWithValues: MeasurementSetting.allCases.map { setting in
            (setting, userDefaults.bool(forKey: setting.storageKey))
        })
        return MeasurementPreference(usesImperialBySetting: valuesBySetting)
    }
}
