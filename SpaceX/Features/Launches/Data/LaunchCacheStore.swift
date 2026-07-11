import Foundation

protocol LaunchCacheStoreProtocol {
    func save(_ launches: [Launch], for rocketId: String)
    func load(for rocketId: String) -> [Launch]?
    func clear(for rocketId: String)
    func allKnownRocketIds() -> [String]
}

final class UserDefaultsLaunchCacheStore: LaunchCacheStoreProtocol {
    private static let knownIdsKey = "launchCache_v4_knownRocketIds"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = AppLogger.make("UserDefaultsLaunchCacheStore")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ launches: [Launch], for rocketId: String) {
        do {
            let data = try encoder.encode(launches)
            defaults.set(data, forKey: cacheKey(for: rocketId))
            updateKnownIds(adding: rocketId)
            logger.debug("Saved \(launches.count) launches for rocket \(rocketId, privacy: .public)")
        } catch {
            logger.error("Cache encode failed for rocket \(rocketId, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func load(for rocketId: String) -> [Launch]? {
        guard let data = defaults.data(forKey: cacheKey(for: rocketId)) else {
            logger.debug("Cache miss for rocket \(rocketId, privacy: .public)")
            return nil
        }

        do {
            let launches = try decoder.decode([Launch].self, from: data)
            logger.debug("Cache hit for rocket \(rocketId, privacy: .public): \(launches.count) items")
            return launches
        } catch {
            logger.warning("Cache decode failed for rocket \(rocketId, privacy: .public) - returning nil")
            return nil
        }
    }

    func clear(for rocketId: String) {
        defaults.removeObject(forKey: cacheKey(for: rocketId))
        updateKnownIds(removing: rocketId)
    }

    func allKnownRocketIds() -> [String] {
        defaults.stringArray(forKey: Self.knownIdsKey) ?? []
    }

    private func cacheKey(for rocketId: String) -> String {
        "launches_v4_\(rocketId)"
    }

    private func updateKnownIds(adding rocketId: String) {
        var ids = Set(allKnownRocketIds())
        ids.insert(rocketId)
        defaults.set(Array(ids), forKey: Self.knownIdsKey)
    }

    private func updateKnownIds(removing rocketId: String) {
        var ids = Set(allKnownRocketIds())
        ids.remove(rocketId)
        defaults.set(Array(ids), forKey: Self.knownIdsKey)
    }
}
