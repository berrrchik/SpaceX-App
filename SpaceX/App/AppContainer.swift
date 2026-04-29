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
    lazy var rocketRemoteDataSource: RocketRemoteDataSourceProtocol = RocketRemoteDataSource(httpClient: httpClient)
    lazy var launchRemoteDataSource: LaunchRemoteDataSourceProtocol = LaunchRemoteDataSource(httpClient: httpClient)
    lazy var rocketRepository: RocketRepositoryProtocol = RocketRepository(remoteDataSource: rocketRemoteDataSource)
    lazy var launchRepository: LaunchRepositoryProtocol = LaunchRepository(remoteDataSource: launchRemoteDataSource)
    lazy var dateFormatter: DateFormatting = DefaultDateFormatter()
    lazy var rocketFormatter: RocketFormatting = DefaultRocketFormatter()
    lazy var rocketViewModel = RocketViewModel(rocketRepository: rocketRepository)
    lazy var launchListViewModel = LaunchListViewModel(launchRepository: launchRepository, dateFormatter: dateFormatter)

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(settingsStore: settingsStore)
    }
}
