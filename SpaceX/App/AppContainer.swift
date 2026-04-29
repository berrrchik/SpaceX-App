import Foundation

final class AppContainer {
    private let userDefaults: UserDefaults
    private let baseURL = URL(string: "https://api.spacexdata.com")!

    lazy var settingsStore: SettingsStore = UserDefaultsSettingsStore(userDefaults: userDefaults)
    lazy var requestBuilder: RequestBuilding = RequestBuilder(baseURL: baseURL)
    lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }()
    lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: urlSession, requestBuilder: requestBuilder)
    lazy var rocketService: RocketServiceProtocol = RocketService(httpClient: httpClient)
    lazy var launchService: LaunchServiceProtocol = LaunchService(httpClient: httpClient)
    lazy var rocketViewModel = RocketViewModel(rocketApiService: rocketService)
    lazy var launchViewModel = LaunchViewModel(launchApiService: launchService)

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(settingsStore: settingsStore)
    }
}
