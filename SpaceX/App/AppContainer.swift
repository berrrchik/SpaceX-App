import Foundation

final class AppContainer {
    private let userDefaults: UserDefaults
    private let baseURL = URL(string: "https://api.spacexdata.com")!

    lazy var settingsStore: SettingsStore = UserDefaultsSettingsStore(userDefaults: userDefaults)
    lazy var requestBuilder: RequestBuilding = RequestBuilder(baseURL: baseURL)
    lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        // 30 s per request gives the SpaceX API enough time to respond even on
        // slower connections (was 8 s, which fired before the server replied).
        configuration.timeoutIntervalForRequest = 30
        // 60 s total resource window keeps large paginated responses from timing out.
        configuration.timeoutIntervalForResource = 60
        // Wait for the network to become available instead of failing immediately.
        configuration.waitsForConnectivity = true
        // POST responses must not be served from cache.
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
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
