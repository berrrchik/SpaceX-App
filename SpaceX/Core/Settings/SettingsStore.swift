import Foundation

protocol SettingsStoreObserver: AnyObject {
    func settingsStore(_ settingsStore: SettingsStore, didUpdate preference: MeasurementPreference)
}

protocol SettingsStore: AnyObject {
    var measurementPreference: MeasurementPreference { get }
    func updateMeasurementPreference(_ preference: MeasurementPreference)
    func addObserver(_ observer: SettingsStoreObserver)
    func removeObserver(_ observer: SettingsStoreObserver)
}
