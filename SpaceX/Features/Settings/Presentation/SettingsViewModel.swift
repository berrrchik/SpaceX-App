import Foundation

class SettingsViewModel {
    private let settingsStore: SettingsStore
    private var toggleStates: [Bool]

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.toggleStates = settingsStore.measurementPreference.toggleStates()
        settingsStore.addObserver(self)
    }

    deinit {
        settingsStore.removeObserver(self)
    }

    func getToggleStates() -> [Bool] {
        toggleStates
    }

    func toggleState(at index: Int) {
        guard toggleStates.indices.contains(index) else { return }
        toggleStates[index].toggle()
    }

    func saveSettings() {
        settingsStore.updateMeasurementPreference(MeasurementPreference(toggleStates: toggleStates))
    }

    private func refreshToggleStates() {
        toggleStates = settingsStore.measurementPreference.toggleStates()
    }
}

extension SettingsViewModel: SettingsStoreObserver {
    func settingsStore(_ settingsStore: SettingsStore, didUpdate preference: MeasurementPreference) {
        refreshToggleStates()
    }
}
