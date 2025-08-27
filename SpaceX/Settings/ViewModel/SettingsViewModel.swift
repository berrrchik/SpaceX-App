import Foundation

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

class SettingsViewModel {
    
    private let userDefaultsKeys = [
        "isHeightFt",
        "isDiameterft",
        "isMassLb",
        "isPayloadWeightLb"
    ]
    
    private var toggleStates: [Bool]
    
    init() {
        toggleStates = userDefaultsKeys.map { key in
            UserDefaults.standard.bool(forKey: key)
        }
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getToggleStates() -> [Bool] {
        return toggleStates
    }
    
    func toggleState(at index: Int) {
        guard index < toggleStates.count else { return }
        toggleStates[index].toggle()
        saveToggleStates()
    }
    
    func saveSettings() {
        saveToggleStates()
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
    
    private func saveToggleStates() {
        for (index, state) in toggleStates.enumerated() {
            UserDefaults.standard.set(state, forKey: userDefaultsKeys[index])
        }
    }
    
    private func refreshToggleStates() {
        toggleStates = userDefaultsKeys.map { key in
            UserDefaults.standard.bool(forKey: key)
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }
    
    @objc private func settingsDidChange() {
        refreshToggleStates()
    }
}
