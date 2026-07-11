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
    lazy var launchDetailRemoteDataSource: LaunchDetailRemoteDataSourceProtocol = LaunchDetailRemoteDataSource(httpClient: httpClient)
    lazy var launchpadRemoteDataSource: LaunchpadRemoteDataSourceProtocol = LaunchpadRemoteDataSource(httpClient: httpClient)
    lazy var rocketDetailRemoteDataSource: RocketDetailRemoteDataSourceProtocol = RocketDetailRemoteDataSource(httpClient: httpClient)
    lazy var payloadRemoteDataSource: PayloadRemoteDataSourceProtocol = PayloadRemoteDataSource(httpClient: httpClient)
    lazy var crewRemoteDataSource: CrewRemoteDataSourceProtocol = CrewRemoteDataSource(httpClient: httpClient)
    lazy var capsuleRemoteDataSource: CapsuleRemoteDataSourceProtocol = CapsuleRemoteDataSource(httpClient: httpClient)
    lazy var shipRemoteDataSource: ShipRemoteDataSourceProtocol = ShipRemoteDataSource(httpClient: httpClient)
    lazy var rocketFallbackDataSource: RocketFallbackDataSourceProtocol = BundledRocketDataSource()
    lazy var launchFallbackDataSource: LaunchFallbackDataSourceProtocol = BundledLaunchDataSource()
    lazy var rocketCacheStore: RocketCacheStoreProtocol = UserDefaultsRocketCacheStore(defaults: userDefaults)
    lazy var launchCacheStore: LaunchCacheStoreProtocol = UserDefaultsLaunchCacheStore(defaults: userDefaults)
    lazy var rocketRepository: RocketRepositoryProtocol = RocketRepository(
        remoteDataSource: rocketRemoteDataSource,
        cacheStore: rocketCacheStore,
        networkMonitor: networkMonitor,
        fallbackDataSource: rocketFallbackDataSource
    )
    lazy var launchRepository: LaunchRepositoryProtocol = LaunchRepository(
        remoteDataSource: launchRemoteDataSource,
        cacheStore: launchCacheStore,
        networkMonitor: networkMonitor,
        fallbackDataSource: launchFallbackDataSource
    )
    lazy var launchDetailRepository: LaunchDetailRepositoryProtocol = LaunchDetailRepository(
        launchDetailDataSource: launchDetailRemoteDataSource,
        launchpadDataSource: launchpadRemoteDataSource,
        rocketDataSource: rocketDetailRemoteDataSource,
        payloadDataSource: payloadRemoteDataSource,
        crewDataSource: crewRemoteDataSource,
        capsuleDataSource: capsuleRemoteDataSource,
        shipDataSource: shipRemoteDataSource,
        networkMonitor: networkMonitor,
        fallbackDataSource: launchFallbackDataSource
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

    func makeLaunchDetailViewModel(launchId: String) -> LaunchDetailViewModel {
        LaunchDetailViewModel(launchId: launchId, repository: launchDetailRepository)
    }
}
