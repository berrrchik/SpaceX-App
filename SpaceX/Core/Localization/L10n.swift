import Foundation

enum L10n {
    static let alertErrorTitle = localized("alert.error.title")
    static let alertOk = localized("alert.ok")
    static let navigationBack = localized("navigation.back")

    static let loadingData = localized("loading.data")

    static let settingsTitle = localized("settings.title")
    static let settingsClose = localized("settings.close")
    static let settingsHeight = localized("settings.height")
    static let settingsDiameter = localized("settings.diameter")
    static let settingsMass = localized("settings.mass")
    static let settingsPayload = localized("settings.payload")

    static let rocketFirstFlight = localized("rocket.firstFlight")
    static let rocketCountry = localized("rocket.country")
    static let rocketCostPerLaunch = localized("rocket.costPerLaunch")
    static let rocketEnginesCount = localized("rocket.enginesCount")
    static let rocketFuelAmount = localized("rocket.fuelAmount")
    static let rocketBurnTime = localized("rocket.burnTime")
    static let rocketFirstStage = localized("rocket.firstStage")
    static let rocketSecondStage = localized("rocket.secondStage")
    static let rocketShowLaunches = localized("rocket.showLaunches")
    static let rocketLoadErrorMessage = localized("rocket.loadError")

    static let launchesNoData = localized("launches.noData")
    static let launchesNetworkError = localized("launches.networkError")

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
