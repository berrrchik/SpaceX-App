import Foundation

protocol RocketCacheStoreProtocol {
    func save(_ rockets: [Rocket])
    func load() -> [Rocket]?
    func clear()
}

final class UserDefaultsRocketCacheStore: RocketCacheStoreProtocol {
    private let cacheKey = "rockets_all"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = AppLogger.make("UserDefaultsRocketCacheStore")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ rockets: [Rocket]) {
        do {
            let data = try encoder.encode(rockets)
            defaults.set(data, forKey: cacheKey)
            logger.debug("Saved \(rockets.count) rockets to cache")
        } catch {
            logger.error("Rocket cache encode failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func load() -> [Rocket]? {
        guard let data = defaults.data(forKey: cacheKey) else {
            logger.debug("Rocket cache miss")
            return nil
        }
        do {
            let rockets = try decoder.decode([Rocket].self, from: data)
            logger.debug("Rocket cache hit: \(rockets.count) rockets")
            return rockets
        } catch {
            logger.warning("Rocket cache decode failed - returning nil")
            return nil
        }
    }

    func clear() {
        defaults.removeObject(forKey: cacheKey)
    }
}
