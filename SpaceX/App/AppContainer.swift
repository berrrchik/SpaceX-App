import Foundation

final class AppContainer {
    private let userDefaults: UserDefaults
    private let baseURL = URL(string: "https://api.spacexdata.com")!

    lazy var settingsStore: SettingsStore = UserDefaultsSettingsStore(userDefaults: userDefaults)
    lazy var requestBuilder: RequestBuilding = RequestBuilder(baseURL: baseURL)
    lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()
    lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: urlSession, requestBuilder: requestBuilder)
    lazy var networkMonitor: NetworkMonitorProtocol = NetworkMonitor()
    lazy var rocketRemoteDataSource: RocketRemoteDataSourceProtocol = RocketRemoteDataSource(httpClient: httpClient)
    lazy var launchRemoteDataSource: LaunchRemoteDataSourceProtocol = LaunchRemoteDataSource(httpClient: httpClient)
    lazy var rocketCacheStore: RocketCacheStoreProtocol = UserDefaultsRocketCacheStore(defaults: userDefaults)
    lazy var launchCacheStore: LaunchCacheStoreProtocol = UserDefaultsLaunchCacheStore(defaults: userDefaults)
    lazy var rocketRepository: RocketRepositoryProtocol = RocketRepository(
        remoteDataSource: rocketRemoteDataSource,
        cacheStore: rocketCacheStore,
        networkMonitor: networkMonitor
    )
    lazy var launchRepository: LaunchRepositoryProtocol = LaunchRepository(
        remoteDataSource: launchRemoteDataSource,
        cacheStore: launchCacheStore,
        networkMonitor: networkMonitor
    )
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
